`timescale 1ns/1ns

module tb_hs_clk_ctrl();
    // Parameters
    localparam TCLK = 10; // 100MHz
    localparam ZERO_CLK = 27;
    localparam RX_SETUP = 4;
    localparam POST_DATA = 6;
    localparam STOP_CLK = 6;
    
    // Signals
    logic clk, rst;
    logic hs_enable, time_pass, hs_req;
    logic hs_clk, hs_active;
    logic timer_enable;
    logic [5:0] timer_reload;
    
    // Instantiate DUT
    hs_clk_ctrl dut (
        .clk(clk),
        .rst(rst),
        .hs_enable(hs_enable),
        .time_pass(time_pass),
        .hs_req(hs_req),
        .hs_clk(hs_clk),
        .hs_active(hs_active),
        .timer_enable(timer_enable),
        .timer_reload(timer_reload)
    );
    
    // Clock generation
    always #(TCLK/2) clk = ~clk;

    // Test scenarios
    task test_reset();
        $display("=== Test 1: Reset Test ===");
        rst = 1;
        hs_enable = 0;
        hs_req = 0;
        #100;
        rst = 0;
        #100;
        
        if (hs_clk === 0 && hs_active === 0 && timer_enable === 0)
            $display("Reset test: PASSED");
        else
            $display("Reset test: FAILED");
    endtask
    
    task test_normal_operation();
        $display("=== Test 2: Normal Operation Test ===");
        
        // Enable HS mode and request
        hs_enable = 1;
        hs_req = 1;
        
        
        // Wait for HS_START to CLK_PREPARE transition
        wait(dut.current_state == dut.HS_START);
        $display("Entered HS_START state");
        

        // Wait for timer to expire 
        #(ZERO_CLK * TCLK);
        @(posedge clk);
            time_pass = 1;
        #TCLK;
            time_pass =0;  
        // Should be in CLK_PREPARE state
        wait (dut.current_state == dut.CLK_PREPARE);
            $display("Transition to CLK_PREPARE: PASSED");

        
        // Wait for RX_SETUP cycles
        #(RX_SETUP * TCLK);
        @(posedge clk);
            time_pass = 1;
        #TCLK;
            time_pass =0;  
        
        // Should be in HS_ACTIVE state
        wait (dut.current_state == dut.HS_ACTIVE && hs_active && hs_clk)
            $display("Transition to HS_ACTIVE: PASSED");
        
        // Keep active for some time
        repeat(20) @(posedge clk);
        
        // End transmission
        hs_req = 0;
        
        // Wait for transition to PRE_HS_STOP
        wait(dut.current_state == dut.PRE_HS_STOP);
        $display("Entered PRE_HS_STOP state");
        
        // Wait for POST_DATA cycles
        #(POST_DATA * TCLK);
        @(posedge clk);
            time_pass = 1;
        #TCLK;
            time_pass =0;
        
        // Should be in HS_STOP state
        wait (dut.current_state == dut.HS_STOP);
            $display("Transition to HS_STOP: PASSED");
        
        // Wait for STOP_CLK cycles
        #(STOP_CLK * TCLK);
        @(posedge clk);
            time_pass = 1;
        #TCLK;
            time_pass =0;
        
        // Should return to IDLE_OFF
        wait (dut.current_state == dut.IDLE_OFF);
            $display("Return to IDLE_OFF: PASSED");
    endtask
    
    // Main test sequence
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        hs_enable = 0;
        hs_req = 0;
        time_pass = 0;
        
        // Create waveform file
        $dumpfile("hs_clk_ctrl.vcd");
        $dumpvars(0, tb_hs_clk_ctrl);
        
        // Run tests
        #100;
        rst = 0;
        #100;
        
        test_reset();
        #100;
        
        test_normal_operation();
        #100;

        $display("=== All Tests Completed ===");
        $finish;
    end
    
endmodule