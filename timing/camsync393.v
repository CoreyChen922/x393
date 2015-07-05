/*******************************************************************************
 * Module: camsync393
 * Date:2015-07-03  
 * Author: andrey     
 * Description: Synchronization between cameras using GPIO lines:
 *  - triggering from selected line(s) with filter;
 *  - programmable delay to actual trigger (in pixel clock periods)
 *  - Generating trigger output to selected GPIO line (and polarity)
 *    or directly to the input delay generator (see bove)
 *  - single/repetitive output with specified period in pixel clocks
 *
 * Copyright (C) 2007-2015 Elphel, Inc
 * jp_channel.v is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  jp_channel.v is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/> .
 *******************************************************************************/
 
 // TODO: make a separate clock for transmission (program counters too?) and/or for the period timer?
 // TODO: change timestamp to serial message
 // TODO: see what depends on pclk and if can be made independent of the sensor clock.

module camsync393       #(
    parameter CAMSYNC_ADDR =                    'h160, //TODO: assign valid adderss
    parameter CAMSYNC_MASK =                    'h3f8,
    parameter CAMSYNC_MODE =                    'h0,
    parameter CAMSYNC_TRIG_SRC =                'h4, // setup trigger source
    parameter CAMSYNC_TRIG_DELAY =              'h5, // setup input trigger delay
    parameter CAMSYNC_TRIG_DST =                'h6, // setup trigger destination line(s)
    parameter CAMSYNC_TRIG_PERIOD =             'h7, // setup output trigger period
    
    parameter CAMSYNC_SNDEN_BIT =               'h1, // enable writing ts_snd_en
    parameter CAMSYNC_EXTERNAL_BIT =            'h3, // enable writing ts_external
    
    parameter CAMSYNC_PRE_MAGIC =               6'b110100,
    parameter CAMSYNC_POST_MAGIC =              6'b001101

    )(
    input                         rst,  // global reset
    input                         mclk, // @posedge (was negedge) AF2015: check external inversion - make it @posedge mclk
    input                   [7:0] cmd_ad,      // byte-serial command address/data (up to 6 bytes: AL-AH-D0-D1-D2-D3 
    input                         cmd_stb,     // strobe (with first byte) for the command a/d
                           // 0 - mode: [1:0] +2 - reset ts_snd_en, +3 - set ts_snd_en - enable sending timestamp over sync line
                           //           [3:2] +8 - reset ts_external, +'hc - set ts_external:
                           //                  1 - use external timestamp, if available. 0 - always use local ts
                           // 4 - source of trigger (10 bit pairs, LSB - level to trigger, MSB - use this bit). All 0 - internal trigger
                           //     in internal mode output has variable delay from the internal trigger (relative to sensor trigger)
                           
                           // 5 - input trigger delay (pixel clocks) (NOTE: 0 - trigger disabled - WRONG)
                           // 6 - 10 bit pairs: MSB - enable selected line, LSB - level to send when trigger active
                           //     bit 25==1 some of the bits use test mode signals:
                           // 7 - output trigger period (duration constant of 256 pixel clocks). 
                           //     d==0 - disable (stop periodic mode)
                           //     d==1 - single trigger
                           //     d==2..255 - set output pulse / input-output serial bit duration (no start generated)
                           //     256>=d - repetitive trigger
    input                         pclk,    // pixel clock (global)
    
    input                         triggered_mode, // use triggered mode (0 - sensor is free-running)
    input                         trigrst,   // single-clock start of frame input (resets trigger output) posedge
    input                  [9:0]  gpio_in, // 12-bit input from GPIO pins -> 10 bit
    output                 [9:0]  gpio_out,// 12-bit output to GPIO pins
    output reg             [9:0]  gpio_out_en,// 12-bit output enable to GPIO pins
    output                        trigger1, // 1 cycle-long trigger output
    output                        trigger, // active high trigger to the sensor (reset by vacts)
    output reg                    overdue,     // prevents lock-up when no vact was detected during one period and trigger was toggled
    
// TODO: change to control bit fields    
//    input                         ts_snd_en,   // enable sending timestamp over sync line
//    input                         ts_external, // 1 - use external timestamp, if available. 0 - always use local ts
    
    // getting timestamp from rtc module, all @posedge mclk (from timestmp_snapshot)
    // this timestmp is used either to send local timestamp for synchronization, or
    // to acquire local timestamp of sync pulse for logging
    output                        ts_snap_mclk,     // make a timestamp pulse  single @(posedge pclk)
                                      // timestamp should be valid in <16 pclk cycles
    input                         ts_snd_stb,  // 1 clk before ts_snd_data is valid
    input                   [7:0] ts_snd_data, // byte-wide serialized timestamp message  

// TODO: remove next 2                                     
//    input                  [31:0] ts_snd_sec,  // [31:0] timestamp seconds to be sent over the sync line
//    input                  [19:0] ts_snd_usec, // [19:0] timestamp microseconds to be sent over the sync line
    //ts_rcv_*sec (@mclk) goes to the following receivers:
                //ts_sync_*sec (synchronized to sensor clock) -> timestamp353
                //ts_sync_*sec (synchronized to sensor clock) -> compressor
                //ts_sync_*sec (synchronized to sensor clock) -> imu_logger
    
    output                        ts_rcv_stb, // 1 clock before ts_rcv_data is valid
    output                  [7:0] ts_rcv_data // byte-wide serialized timestamp message received or local

// TODO: remove next 3                                     
//    output reg             [31:0] ts_rcv_sec,  // [31:0] timestamp seconds received over the sync line
//    output reg             [19:0] ts_rcv_usec,// [19:0] timestamp microseconds received over the sync line
//    output                        ts_stb);    // strobe when received timestamp is valid
);

// TODO: change to control bit fields    
    reg           ts_snd_en;   // enable sending timestamp over sync line
    reg           ts_external; // 1 - use external timestamp, if available. 0 - always use local ts
    
// TODO: remove next 2                                     
    wire   [31:0] ts_snd_sec;  // [31:0] timestamp seconds to be sent over the sync line
    wire   [19:0] ts_snd_usec; // [19:0] timestamp microseconds to be sent over the sync line

    reg    [31:0] ts_rcv_sec;  // [31:0] timestamp seconds received over the sync line
    reg    [19:0] ts_rcv_usec;// [19:0] timestamp microseconds received over the sync line
    wire          ts_stb;    // strobe when received timestamp is valid

    
    
    wire    [2:0] cmd_a;       // command address
    wire   [31:0] cmd_data;    // command data TODO: trim  
    wire          cmd_we;      // command write enable
    
    wire          set_mode_reg_w;
    wire          set_trig_src_w;
    wire          set_trig_delay_w;
    wire          set_trig_dst_w;
    wire          set_trig_period_w;
    wire    [9:0] pre_input_use;
    wire    [9:0] pre_input_pattern;        
      

// delaying everything by 1 clock to reduce data fan in
    reg           high_zero;       // 24 MSBs are zero 
    reg     [9:0] input_use;       // 1 - use this bit
    reg     [9:0] input_pattern;   // data to be compared for trigger event to take place
    reg           pre_input_use_intern;// @(posedge mclk) Use internal trigger generator, 0 - use external trigger (also switches delay from input to output)
    reg           input_use_intern;//  @(posedge clk) 
    reg    [31:0] input_dly;       // delay value for the trigger
    reg     [9:0] gpio_active;     // output levels on the selected GPIO lines during output pulse (will be negated when inactive)
    reg           testmode;        // drive some internal signals to GPIO bits
    reg           outsync;         // during output active
    reg           out_data;        // output data (modulated with timestamp if enabled)
    reg    [31:0] repeat_period;    // restart period in repetitive mode
    reg           start,start_d;   // start single/repetitive output pulse(s)
    reg           rep_en;          // enable repetitive mode
    reg           start_en;
    wire          start_to_pclk;
    reg    [2:0]  start_pclk; // start and restart
    reg   [31:0]  restart_cntr; // restart period counter
    reg    [1:0]  restart_cntr_run; // restart counter running
    wire          restart;          // restart out sync
    reg           trigger_condition; // GPIO input trigger condition met
    reg           trigger_condition_d; // GPIO input trigger condition met, delayed (for edge detection)
    reg           trigger_condition_filtered; // trigger condition filtered
    reg    [6:0]  trigger_filter_cntr;
    reg           trigger1_r;
//    wire          trigger1_dly16; // trigger1 delayed by 16 clk cycles to get local timestamp
    reg           trigger_r=0;       // for happy simulator
    reg           start_dly;      // start delay (external input filtered or from internal single/rep)
    reg   [31:0]  dly_cntr;       // trigger delay counter
    reg           dly_cntr_run=0;   // trigger delay counter running (to use FD for simulation)
    reg           dly_cntr_run_d=0; // trigger delay counter running - delayed by 1
    wire          pre_start_out_pulse;
    reg           start_out_pulse; /// start generation of output pulse. In internal trigger mode uses delay counter, in external - no delay
    reg   [31:0]  pre_period;
    reg   [ 7:0]  bit_length='hff; /// Output pulse duration or bit duration in timestamp mode
                                   /// input will be filtered with (bit_length>>2) duration
    wire  [ 7:0]  bit_length_plus1; // bit_length+1
    reg   [ 7:0]  bit_length_short; /// 3/4 bit duration, delay for input strobe from the leading edge.
                                   
    wire          pre_start0;
    reg           start0;
    wire          pre_set_bit;
    reg           set_bit;
    wire          pre_set_period;
    reg           set_period;
    wire          start_late ;// delayed start to wait for time stamp to be available

    reg   [31:0]  sr_snd_first;
    reg   [31:0]  sr_snd_second;

    reg   [31:0]  sr_rcv_first;
    reg   [31:0]  sr_rcv_second;
    reg   [ 7:0]  bit_snd_duration;
    reg   [ 5:0]  bit_snd_counter;
    reg   [ 7:0]  bit_rcv_duration;
    reg           bit_rcv_duration_zero; // to make it faster, duration always >=2
    reg   [ 6:0]  bit_rcv_counter; // includes "deaf" period ater receving
    reg           bit_snd_duration_zero; //    
    reg           ts_snd_en_pclk;
    
    reg           rcv_run_or_deaf; // counters active
    wire          rcv_run;     // receive in progress, will always last for 64 bit_length+1 intervals before ready for the new input pulse
    reg           rcv_run_d;
    reg           rcv_done_rq; // request to copy time stamp (if it is not ready yet)
    reg           rcv_done_rq_d;
    reg           rcv_done;  // rcv_run ended, copy timestamp if requested
    wire          rcv_done_mclk; // rcv_done re-clocked @mclk 
    wire          pre_rcv_error;  // pre/post magic does not match, set ts to all ff-s
    reg           rcv_error;

    reg           ts_external_pclk; // 1 - use external timestamp (combines ts_external and input_use_intern)
    reg           triggered_mode_pclk;
    
//    reg           ts_stb_r;         // strobe when received timestamp is valid (single mclk cycle)
//    reg           ts_stb_pclk;
//    reg     [2:0] ts_pre_stb;
    
    wire          local_got; // received local timestamp (@ posedge mclk)
    wire          local_got_pclk; // local_got reclocked @pclk
    reg           ts_snap;     // make a timestamp pulse  single @(posedge pclk)

//! in testmode GPIO[9] and GPIO[8] use internal signals instead of the outsync:
//! bit 11 - same as TRIGGER output to the sensor (signal to the sensor may be disabled externally)
//!          then that bit will be still from internall trigger to frame valid
//! bit 10 - dly_cntr_run (delay counter run) - active during trigger delay
    assign rcv_run=rcv_run_or_deaf && bit_rcv_counter[6];
    assign bit_length_plus1 [ 7:0] =bit_length[7:0]+1;

    assign pre_start_out_pulse=input_use_intern?(dly_cntr_run_d && !dly_cntr_run):start_late;


    assign  gpio_out[7: 0] = out_data? gpio_active[7: 0]: ~gpio_active[7: 0];
    assign  gpio_out[8] = (testmode? dly_cntr_run: out_data)? gpio_active[8]: ~gpio_active[8];
    assign  gpio_out[9] = (testmode? trigger_r:      out_data)? gpio_active[9]: ~gpio_active[9];
    assign  restart= restart_cntr_run[1] && !restart_cntr_run[0];
    
    assign  pre_set_bit=     (|cmd_data[31:8]==0) && |cmd_data[7:1]; // 2..255
    assign  pre_start0=       |cmd_data[31:0] && !pre_set_bit;
    assign  pre_set_period = !pre_set_bit;

    assign trigger =  trigger_r;
    assign trigger1 = trigger1_r;
//    assign ts_stb =   ts_stb_r;
    
    assign set_mode_reg_w =     cmd_we && (cmd_a == CAMSYNC_MODE);
    assign set_trig_src_w =     cmd_we && (cmd_a == CAMSYNC_TRIG_SRC);
    assign set_trig_delay_w =   cmd_we && (cmd_a == CAMSYNC_TRIG_DELAY);
    assign set_trig_dst_w =     cmd_we && (cmd_a == CAMSYNC_TRIG_DST);
    assign set_trig_period_w =  cmd_we && (cmd_a == CAMSYNC_TRIG_PERIOD);
    assign pre_input_use = {cmd_data[19],cmd_data[17],cmd_data[15],cmd_data[13],cmd_data[11],cmd_data[9],cmd_data[7],cmd_data[5],cmd_data[3],cmd_data[1]};
    assign pre_input_pattern = {cmd_data[18],cmd_data[16],cmd_data[14],cmd_data[12],cmd_data[10],cmd_data[8],cmd_data[6],cmd_data[4],cmd_data[2],cmd_data[0]};        

    always @(posedge mclk) begin
        if (set_mode_reg_w) begin
            if (cmd_data[CAMSYNC_SNDEN_BIT])    ts_snd_en <=   cmd_data[CAMSYNC_SNDEN_BIT - 1];
            if (cmd_data[CAMSYNC_EXTERNAL_BIT]) ts_external <= cmd_data[CAMSYNC_EXTERNAL_BIT - 1];
        end 
        if (set_trig_src_w) begin
            input_use <= pre_input_use;
            input_pattern <= pre_input_pattern;        
            pre_input_use_intern <= (pre_input_use == 0); // use internal source for triggering
        end
        if (set_trig_delay_w) begin 
            input_dly[31:0] <= cmd_data[31:0];
        end
        if (set_trig_dst_w) begin
            gpio_out_en[9:0] <= {cmd_data[19],cmd_data[17],cmd_data[15],cmd_data[13],cmd_data[11],cmd_data[9],cmd_data[7],cmd_data[5],cmd_data[3],cmd_data[1]};
            gpio_active[9:0] <= {cmd_data[18],cmd_data[16],cmd_data[14],cmd_data[12],cmd_data[10],cmd_data[8],cmd_data[6],cmd_data[4],cmd_data[2],cmd_data[0]};
            testmode <= cmd_data[24];
        end
        if (set_trig_period_w) begin
            pre_period[31:0] <= cmd_data[31:0];
            high_zero        <= cmd_data[31:8]==24'b0;
        end
        start0     <= set_trig_period_w && pre_start0;
        set_bit    <= set_trig_period_w && pre_set_bit;
        set_period <= set_trig_period_w && pre_set_period;
        
        if (set_period) repeat_period[31:0] <= pre_period[31:0];
        if (set_bit)        bit_length[7:0] <= pre_period[ 7:0];
     
        start  <= start0;
        start_d <= start;

        start_en <= (repeat_period[31:0]!=0);
        if (set_period) rep_en <= !high_zero;
    end
    
    always @ (posedge pclk) begin
     ts_snap <=  (start_pclk[2] && ts_snd_en_pclk) || //strobe by internal generator if output timestamp is enabled
                 (trigger1_r && !ts_external_pclk); // get local timestamp of trigger1_r if it is used

      ts_snd_en_pclk<=ts_snd_en;
      input_use_intern <= pre_input_use_intern;
      ts_external_pclk<= ts_external && !input_use_intern;
     
      start_pclk[2:0] <= {(restart && rep_en) || (start_pclk[1] && !restart_cntr_run[1] && !restart_cntr_run[0] && !start_pclk[2]),
                          start_pclk[0],
                          start_to_pclk && !start_pclk[0]};
      restart_cntr_run[1:0] <= {restart_cntr_run[0],start_en && (start_pclk[2] || (restart_cntr_run[0] && (restart_cntr[31:2] !=0)))};
      if (restart_cntr_run[0]) restart_cntr[31:0] <= restart_cntr[31:0] - 1;
      else restart_cntr[31:0] <= repeat_period[31:0];
      
      start_out_pulse <= pre_start_out_pulse;
/// Generating output pulse - 64* bit_length if timestamp is disabled or
/// 64 bits with encoded timestamp, including pre/post magic for error detectrion
      outsync <= start_en && (start_out_pulse || (outsync && !((bit_snd_duration[7:0]==0) &&(bit_snd_counter[5:0]==0))));
      if (!outsync || (bit_snd_duration[7:0]==0)) bit_snd_duration[7:0] <= bit_length[7:0];
      else  bit_snd_duration[7:0] <= bit_snd_duration[7:0] - 1;
      bit_snd_duration_zero <= bit_snd_duration[7:0]==8'h1;

      if (!outsync) bit_snd_counter[5:0] <=ts_snd_en_pclk?63:3; /// when no ts serial, send pulse 4 periods long (max 1024 pclk)
      /// Same bit length (1/4) is used in input filter/de-glitcher
      else if (bit_snd_duration[7:0]==0)  bit_snd_counter[5:0] <=  bit_snd_counter[5:0] -1;

      if (!outsync)                       sr_snd_first[31:0]  <= {CAMSYNC_PRE_MAGIC,ts_snd_sec[31:6]};
      else if (bit_snd_duration_zero)     sr_snd_first[31:0]  <={sr_snd_first[30:0],sr_snd_second[31]};
      if (!outsync)                       sr_snd_second[31:0] <= {ts_snd_sec[5:0], ts_snd_usec[19:0],CAMSYNC_POST_MAGIC};
      else if (bit_snd_duration_zero)     sr_snd_second[31:0] <={sr_snd_second[30:0],1'b0};
      out_data <=outsync && (ts_snd_en_pclk?sr_snd_first[31]:1'b1);
      
    end
 
    always @ (posedge rst or posedge pclk) begin
        if (rst) dly_cntr_run <= 0;
        else     dly_cntr_run <= triggered_mode && (start_dly || (dly_cntr_run && (dly_cntr[31:0]!=0)));
        if (rst) trigger_r <= 0;
        else     trigger_r <= trigrst?1'b0:(trigger1_r ^ trigger_r);
    end
 
 
// Detecting input sync pulse (filter - 64 pclk, pulse is 256 pclk)
// even more for simulator
//      FD i_dly_cntr_run (.C(pclk),.D(triggered_mode && (start_dly || (dly_cntr_run && (dly_cntr[31:0]!=0)))),.Q(dly_cntr_run)); // for simulator to be happy

/// Now trigger1_r toggles trigger output to prevent lock-up if no vacts
/// Lock-up could take place if:
/// 1 - Sensoris in snapshot mode
/// 2 - trigger was applied before end of previous frame.
/// With implemented toggling 1 extra pulse can be missed (2 with the original missed one), but the system will not lock-up 
/// if the trigger pulses continue to come.

    assign pre_rcv_error= (sr_rcv_first[31:26]!=CAMSYNC_PRE_MAGIC) || (sr_rcv_second[5:0]!=CAMSYNC_POST_MAGIC);
//    FD i_trigger      (.C(pclk),.D(trigrst?1'b0:(trigger1_r ^ trigger)),  .Q(trigger)); // for simulator to be happy
    always @ (posedge pclk) begin
      if (trigrst)       overdue <= 1'b0;
      else if (trigger1_r) overdue <= trigger;

      triggered_mode_pclk<= triggered_mode;
      bit_length_short[7:0] <= bit_length[7:0]-bit_length_plus1[7:2]-1; // 3/4 of the duration

      trigger_condition <= (((gpio_in[9:0] ^ input_pattern[9:0]) & input_use[9:0]) == 10'b0);
      trigger_condition_d <= trigger_condition;
     
      if (!triggered_mode || (trigger_condition !=trigger_condition_d)) trigger_filter_cntr <= {1'b0,bit_length[7:2]};
      else if (!trigger_filter_cntr[6]) trigger_filter_cntr<=trigger_filter_cntr-1;
     
      if (input_use_intern) trigger_condition_filtered <= 1'b0;
      else if (trigger_filter_cntr[6]) trigger_condition_filtered <= trigger_condition_d;
      
                                     
      rcv_run_or_deaf <= start_en && (trigger_condition_filtered ||
                                     (rcv_run_or_deaf && !(bit_rcv_duration_zero  && (bit_rcv_counter[6:0]==0))));

      rcv_run_d <= rcv_run; 
      start_dly <= input_use_intern ? (start_late && start_en) : (rcv_run && !rcv_run_d);
// simulation problems w/o "start_en &&" ? 

      dly_cntr_run_d <= dly_cntr_run;
      if (dly_cntr_run) dly_cntr[31:0] <= dly_cntr[31:0] -1;
      else              dly_cntr[31:0] <= input_dly[31:0];
      trigger1_r <= input_use_intern ? (start_late && start_en):(dly_cntr_run_d && !dly_cntr_run);/// bypass delay to trigger1_r in internal trigger mode
/// 64-bit serial receiver (52 bit payload, 6 pre magic and 6 bits post magic for error checking
      if      (!rcv_run_or_deaf)         bit_rcv_duration[7:0] <= bit_length_short[7:0]; // 3/4 bit length-1
      else if (bit_rcv_duration[7:0]==0) bit_rcv_duration[7:0] <= bit_length[7:0];       // bit length-1
      else                               bit_rcv_duration[7:0] <= bit_rcv_duration[7:0]-1;
      bit_rcv_duration_zero <= bit_rcv_duration[7:0]==8'h1;
      if      (!rcv_run_or_deaf)         bit_rcv_counter[6:0]  <= 127;
      else if (bit_rcv_duration_zero)    bit_rcv_counter[6:0]  <= bit_rcv_counter[6:0] -1;

      if (rcv_run && bit_rcv_duration_zero) begin
        sr_rcv_first[31:0]  <={sr_rcv_first[30:0],sr_rcv_second[31]}; 
        sr_rcv_second[31:0] <={sr_rcv_second[30:0],trigger_condition_filtered};
      end

      rcv_done_rq <= start_en && ((ts_external_pclk && local_got_pclk) || (rcv_done_rq && rcv_run));
      rcv_done_rq_d <= rcv_done_rq;
      rcv_done <= rcv_done_rq_d && !rcv_done_rq;
      
      rcv_error <= pre_rcv_error;

      if (rcv_done) begin
        ts_rcv_sec  [31:0] <= {sr_rcv_first[25:0],sr_rcv_second[31:26]};
        ts_rcv_usec [19:0] <= rcv_error?20'hfffff:   sr_rcv_second[25:6];
      end else if (!triggered_mode_pclk || (!ts_external_pclk && local_got_pclk )) begin
        ts_rcv_sec  [31:0] <=  ts_snd_sec [31:0];
        ts_rcv_usec [19:0] <=  ts_snd_usec[19:0];
      end
    end

    
    assign ts_stb = rcv_done_mclk || (local_got && (!ts_external || pre_input_use_intern));
    // Making delayed start that waits for timestamp use timestamp_got, otherwize - nothing to wait
    
    assign start_late = ts_snd_en_pclk?local_got_pclk :  start_pclk[2];    
    
    
    cmd_deser #(
        .ADDR       (CAMSYNC_ADDR),
        .ADDR_MASK  (CAMSYNC_MASK),
        .NUM_CYCLES (6),
        .ADDR_WIDTH (3),
        .DATA_WIDTH (32)
    ) cmd_deser_32bit_i (
        .rst        (rst),         // input
        .clk        (mclk),        // input
        .ad         (cmd_ad),      // input[7:0] 
        .stb        (cmd_stb),     // input
        .addr       (cmd_a),       // output[3:0] 
        .data       (cmd_data),    // output[31:0] 
        .we         (cmd_we)       // output
    );

    timestamp_to_parallel timestamp_to_parallel_i (
        .clk        (mclk),        // input
        .pre_stb    (ts_snd_stb),  // input
        .tdata      (ts_snd_data), // input[7:0] 
        .sec        (ts_snd_sec),  // output[31:0] reg 
        .usec       (ts_snd_usec), // output[19:0] reg 
        .done       (local_got)    // output
    );

    timestamp_to_serial timestamp_to_serial_i (
        .clk        (mclk),        // input
        .stb        (ts_stb),      // input
        .sec        (ts_rcv_sec),  // input[31:0] 
        .usec       (ts_rcv_usec), // input[19:0] 
        .tdata      (ts_rcv_data)  // output[7:0] reg 
    );
    assign ts_rcv_stb= ts_stb;
    pulse_cross_clock i_start_to_pclk (.rst(1'b0), .src_clk(mclk), .dst_clk(pclk), .in_pulse(start_d && start_en), .out_pulse(start_to_pclk),.busy());
    pulse_cross_clock i_ts_snap_mclk  (.rst(1'b0), .src_clk(pclk), .dst_clk(mclk), .in_pulse(ts_snap), .out_pulse(ts_snap_mclk),.busy());
    pulse_cross_clock i_rcv_done_mclk (.rst(1'b0), .src_clk(pclk), .dst_clk(mclk), .in_pulse(rcv_done), .out_pulse(rcv_done_mclk),.busy());
    pulse_cross_clock i_local_got_pclk(.rst(1'b0), .src_clk(mclk), .dst_clk(pclk), .in_pulse(local_got), .out_pulse(local_got_pclk),.busy());
    
endmodule

