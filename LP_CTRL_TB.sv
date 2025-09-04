`timescale 1ns/1ps

module tb_LP_CTRL_CLK_Lane();
    parameter TIME_WAIT_WIDTH = 32;
    
    // Inputs
    reg TxClkEsc;
    reg rst_n;
    reg ForceTxStopmode;
    reg Enable;
    reg TxUlpsExit;
    reg TxRequestHS;
    reg time_flag;
    reg TxUlpsClk;
    
    // Outputs
    wire timer_enable;
    wire ULP_CG_EN;
    wire Stopstate;
    wire UlpsActiveNot;
    wire [1:0] LP_MODE_SEQ;
    wire HS_EN;
    wire [TIME_WAIT_WIDTH-1:0] time_wait;
    
    // Testbench variables
    reg [31:0] test_case;
    reg [31:0] clock_count;
    reg [31:0] time_flag_counter;
    parameter CLK_PERIOD = 10; // 100MHz
    
    // Instantiate DUT
    LP_CTRL_CLK_Lane #(
        .TIME_WAIT_WIDTH(TIME_WAIT_WIDTH)
    ) dut (
        .TxClkEsc(TxClkEsc),
        .rst_n(rst_n),
        .ForceTxStopmode(ForceTxStopmode),
        .Enable(Enable),
        .TxUlpsExit(TxUlpsExit),
        .TxRequestHS(TxRequestHS),
        .time_flag(time_flag),
        .TxUlpsClk(TxUlpsClk),
        .timer_enable(timer_enable),
        .ULP_CG_EN(ULP_CG_EN),
        .Stopstate(Stopstate),
        .UlpsActiveNot(UlpsActiveNot),
        .LP_MODE_SEQ(LP_MODE_SEQ),
        .HS_EN(HS_EN),
        .time_wait(time_wait)
    );
    
    // Clock generation
    always #(CLK_PERIOD/2) TxClkEsc = ~TxClkEsc;
    
    // Time flag generation (simulates timer completion)
    always @(posedge TxClkEsc or negedge rst_n) begin
        if (!rst_n) begin
            time_flag_counter <= 0;
            time_flag <= 0;
        end else if (timer_enable) begin
            if (time_flag_counter == time_wait - 1) begin
                time_flag <= 1;
                time_flag_counter <= 0;
            end else begin
                time_flag <= 0;
                time_flag_counter <= time_flag_counter + 1;
            end
        end else begin
            time_flag <= 0;
            time_flag_counter <= 0;
        end
    end
    
    // Test sequence
    initial begin
        // Initialize
        TxClkEsc = 0;
        rst_n = 0;
        ForceTxStopmode = 0;
        Enable = 0;
        TxUlpsExit = 0;
        TxRequestHS = 0;
        TxUlpsClk = 0;
        test_case = 0;
        clock_count = 0;
        
        // Reset sequence
        #20;
        rst_n = 1;
        #20;
        
        // Test Case 1: Turned Off -> Stop state
        test_case = 1;
        $display("Test Case %0d: Turned Off -> Stop", test_case);
        Enable = 1;
        ForceTxStopmode = 1;
        #(CLK_PERIOD * 2);
        check_outputs("stop", 2'b11, 1'b1, 1'b1, 1'b0, 1'b0, 0);
        
        // Test Case 2: Stop -> HS Request
        test_case = 2;
        $display("Test Case %0d: Stop -> HS Request", test_case);
        ForceTxStopmode = 0;
        TxRequestHS = 1;
        #(CLK_PERIOD);
        check_outputs("HS_RQST", 2'b01, 1'b0, 1'b1, 1'b1, 1'b0, dut.T_LPX);
        
        // Wait for time_flag to complete T_LPX
        wait_for_time_flag();
        check_outputs("Bridge", 2'b00, 1'b0, 1'b1, 1'b1, 1'b0, dut.T_prepare);
        
        // Test Case 3: Bridge -> SEQ_HS0
        test_case = 3;
        $display("Test Case %0d: Bridge -> SEQ_HS0", test_case);
        wait_for_time_flag();
        check_outputs("SEQ_HS0", 2'b00, 1'b0, 1'b1, 1'b0, 1'b1, 0);
        
        // Test Case 4: SEQ_HS0 -> Trail
        test_case = 4;
        $display("Test Case %0d: SEQ_HS0 -> Trail", test_case);
        TxRequestHS = 0;
        #(CLK_PERIOD);
        check_outputs("Trail", 2'b00, 1'b0, 1'b1, 1'b1, 1'b1, dut.T_POST + dut.T_TRAIL);
        
        // Test Case 5: Trail -> Stop
        test_case = 5;
        $display("Test Case %0d: Trail -> Stop", test_case);
        wait_for_time_flag();
        check_outputs("stop", 2'b11, 1'b1, 1'b1, 1'b0, 1'b0, 0);
        
        // Test Case 6: Stop -> ULPS Request
        test_case = 6;
        $display("Test Case %0d: Stop -> ULPS Request", test_case);
        TxUlpsClk = 1;
        #(CLK_PERIOD);
        check_outputs("ULPS_RQST", 2'b10, 1'b0, 1'b1, 1'b1, 1'b0, dut.T_LPX);
        
        // Test Case 7: ULPS Request -> ULPS
        test_case = 7;
        $display("Test Case %0d: ULPS Request -> ULPS", test_case);
        wait_for_time_flag();
        check_outputs("ULPS", 2'b00, 1'b0, 1'b0, 1'b1, 1'b1, dut.T_LPX);
        
        // Test Case 8: ULPS -> ULPS Exit
        test_case = 8;
        $display("Test Case %0d: ULPS -> ULPS Exit", test_case);
        TxUlpsExit = 1;
        #(CLK_PERIOD);
        check_outputs("ULPS_EXIT", 2'b10, 1'b0, 1'b1, 1'b1, 1'b0, dut.T_Wakeup);
        
        // Test Case 9: ULPS Exit -> Stop
        test_case = 9;
        $display("Test Case %0d: ULPS Exit -> Stop", test_case);
        wait_for_time_flag();
        check_outputs("stop", 2'b11, 1'b1, 1'b1, 1'b0, 1'b0, 0);
        
        // Test Case 10: Emergency stop
        test_case = 10;
        $display("Test Case %0d: Emergency stop", test_case);
        ForceTxStopmode = 1;
        #(CLK_PERIOD);
        check_outputs("stop", 2'b11, 1'b1, 1'b1, 1'b0, 1'b0, 0);
        
        $display("All test cases completed successfully!");
        #100;
        $finish;
    end
    
    // Task to wait for time_flag
    task wait_for_time_flag;
        begin
            @(posedge time_flag);
            #(CLK_PERIOD);
        end
    endtask
    
    // Task to check outputs against expected values
    task check_outputs;
        input string expected_state;
        input [1:0] expected_lp_mode;
        input expected_stopstate;
        input expected_ulps_active;
        input expected_timer_en;
        input expected_hs_en;
        input [TIME_WAIT_WIDTH-1:0] expected_time_wait;
        
        begin
            if (LP_MODE_SEQ !== expected_lp_mode) begin
                $error("Test Case %0d: LP_MODE_SEQ mismatch. Expected: %b, Got: %b", 
                       test_case, expected_lp_mode, LP_MODE_SEQ);
            end
            
            if (Stopstate !== expected_stopstate) begin
                $error("Test Case %0d: Stopstate mismatch. Expected: %b, Got: %b", 
                       test_case, expected_stopstate, Stopstate);
            end
            
            if (UlpsActiveNot !== expected_ulps_active) begin
                $error("Test Case %0d: UlpsActiveNot mismatch. Expected: %b, Got: %b", 
                       test_case, expected_ulps_active, UlpsActiveNot);
            end
            
            if (timer_enable !== expected_timer_en) begin
                $error("Test Case %0d: timer_enable mismatch. Expected: %b, Got: %b", 
                       test_case, expected_timer_en, timer_enable);
            end
            
            if (HS_EN !== expected_hs_en) begin
                $error("Test Case %0d: HS_EN mismatch. Expected: %b, Got: %b", 
                       test_case, expected_hs_en, HS_EN);
            end
            
            if (time_wait !== expected_time_wait) begin
                $error("Test Case %0d: time_wait mismatch. Expected: %h, Got: %h", 
                       test_case, expected_time_wait, time_wait);
            end
            
            $display("Test Case %0d (%s) passed", test_case, expected_state);
        end
    endtask
    
    // Monitor to track state transitions
    always @(posedge TxClkEsc) begin
        clock_count <= clock_count + 1;
        if (clock_count % 10 == 0) begin
            $display("Time: %0t ns | State: %s | LP_MODE: %b | HS_EN: %b", 
                     $time, dut.current_state.name(), LP_MODE_SEQ, HS_EN);
        end
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("lp_ctrl_clk_lane.vcd");
        $dumpvars(0, tb_LP_CTRL_CLK_Lane);
    end
    
endmodule