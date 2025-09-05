`timescale 1ns / 1ps

module tb_Data_LP_CTL;
    // Inputs
    reg         clk;
    reg         rst;
    reg         Enable;
    reg         ForceTxStopmode;
    reg         TxRequestEsc;
    reg         TxReadyHS;
    reg         TxUlpsEsc;
    reg         TxUlpsExit;
    reg         TxRequestHS;
    reg         TxValidEsc;
    reg         sync_finished;
    reg         hs_finished;
    reg         hs_en;
    reg         lp_mode_eq;
    reg         timer_passed;
    reg         TxLpdtEsc;
    reg  [3:0]  TxTriggerEsc;
    reg  [7:0]  TxDataEsc;
    
    // Outputs
    wire        TxReadyEsc;
    wire        StopState;
    wire        Timer_En;
    wire        UIpsActiveNot;
    wire        HS_EN;
    wire        LP_MODE_SEQ;
    wire        LP_TRAIL_FLAG;
    wire        Clk_Div_En;
    wire        ULP_CG_EN;
    wire        ESC_SER_ENC_EN;
    wire [7:0]  TxData;
    wire [31:0] time_wait;
    
    // Instantiate the Unit Under Test (UUT)
    Data_LP_CTL uut (
        .clk(clk),
        .rst(rst),
        .Enable(Enable),
        .ForceTxStopmode(ForceTxStopmode),
        .TxRequestEsc(TxRequestEsc),
        .TxReadyHS(TxReadyHS),
        .TxUlpsEsc(TxUlpsEsc),
        .TxUlpsExit(TxUlpsExit),
        .TxRequestHS(TxRequestHS),
        .TxValidEsc(TxValidEsc),
        .sync_finished(sync_finished),
        .hs_finished(hs_finished),
        .hs_en(hs_en),
        .lp_mode_eq(lp_mode_eq),
        .timer_passed(timer_passed),
        .TxLpdtEsc(TxLpdtEsc),
        .TxTriggerEsc(TxTriggerEsc),
        .TxDataEsc(TxDataEsc),
        .TxReadyEsc(TxReadyEsc),
        .StopState(StopState),
        .Timer_En(Timer_En),
        .UIpsActiveNot(UIpsActiveNot),
        .HS_EN(HS_EN),
        .LP_MODE_SEQ(LP_MODE_SEQ),
        .LP_TRAIL_FLAG(LP_TRAIL_FLAG),
        .Clk_Div_En(Clk_Div_En),
        .ULP_CG_EN(ULP_CG_EN),
        .ESC_SER_ENC_EN(ESC_SER_ENC_EN),
        .TxData(TxData),
        .time_wait(time_wait)
    );
    
    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock
    
    // Test sequence
    initial begin
        // Initialize inputs
        clk = 0;
        rst = 1;
        Enable = 0;
        ForceTxStopmode = 0;
        TxRequestEsc = 0;
        TxReadyHS = 0;
        TxUlpsEsc = 0;
        TxUlpsExit = 0;
        TxRequestHS = 0;
        TxValidEsc = 0;
        sync_finished = 0;
        hs_finished = 0;
        hs_en = 0;
        lp_mode_eq = 0;
        timer_passed = 0;
        TxLpdtEsc = 0;
        TxTriggerEsc = 0;
        TxDataEsc = 0;
        
        // Apply reset
        #20;
        rst = 0;
        Enable = 1;
        
        // Test Case 1: TURNED_OFF to STOP
        #10;
        ForceTxStopmode = 1;
        #20;
        ForceTxStopmode = 0;
        
        // Test Case 2: STOP to HS_RQST
        #10;
        TxRequestHS = 1;
        TxReadyHS = 1;
        #10;
        timer_passed = 1;
        #10;
        timer_passed = 0;
        
        // Test Case 3: HS_RQST to BRIDGE to HS_TRANSMISSION
        #20;
        timer_passed = 1;
        #10;
        timer_passed = 0;
        #20;
        hs_finished = 1;
        #10;
        hs_finished = 0;
        
        // Test Case 4: Back to STOP and then to LP_RQST
        #20;
        TxRequestHS = 0;
        TxRequestEsc = 1;
        #20;
        timer_passed = 1;
        #10;
        timer_passed = 0;
        
        // Test Case 5: Test ESC command modes
        #20;
        TxTriggerEsc = 4'b0001;  // Test trigger
        #20;
        timer_passed = 1;
        #10;
        timer_passed = 0;
        
        // Test Case 6: Test ULPS mode
        #30;
        TxTriggerEsc = 0;
        TxUlpsEsc = 1;
        #20;
        timer_passed = 1;
        #10;
        timer_passed = 0;
        
        // Test Case 7: Exit ULPS
        #30;
        TxUlpsExit = 1;
        #20;
        TxUlpsExit = 0;
        
        // Test Case 8: Test LPDT mode
        #30;
        TxLpdtEsc = 1;
        TxValidEsc = 1;
        TxDataEsc = 8'hA5;
        #20;
        timer_passed = 1;
        #10;
        timer_passed = 0;
        
        // Add more test cases as needed
        
        #100;
        $finish;
    end
    
    // Monitor outputs
    always @(posedge clk) begin
        $display("Time: %0t, State: %0d, TxData: %h, HS_EN: %b, LP_MODE_SEQ: %b", 
                 $time, uut.current_state, TxData, HS_EN, LP_MODE_SEQ);
    end
    
    // VCD file generation for waveform viewing
    initial begin
        $dumpfile("tb_Data_LP_CTL.vcd");
        $dumpvars(0, tb_Data_LP_CTL);
    end
    
endmodule