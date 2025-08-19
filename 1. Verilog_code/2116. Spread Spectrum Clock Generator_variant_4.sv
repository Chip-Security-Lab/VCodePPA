//SystemVerilog IEEE 1364-2005
module spread_spectrum_clk (
    input  wire        aclk,            // Clock input (renamed from clock_in)
    input  wire        aresetn,         // Active low reset (converted from reset)
    
    // AXI-Stream Slave Interface - Control Path
    input  wire        s_axis_tvalid,   // Input control valid
    output wire        s_axis_tready,   // Input control ready
    input  wire [4:0]  s_axis_tdata,    // Input control data (enable_spread + spread_amount)
    input  wire        s_axis_tlast,    // End of control packet
    
    // AXI-Stream Master Interface - Clock output
    output wire        m_axis_tvalid,   // Output valid
    input  wire        m_axis_tready,   // Output ready
    output wire [0:0]  m_axis_tdata     // Output data (clock_out)
);

    // Extract control signals from AXI-Stream input
    wire        enable_spread = s_axis_tdata[4];
    wire [3:0]  spread_amount = s_axis_tdata[3:0];
    
    // Internal reset (active high) conversion
    wire reset = ~aresetn;
    
    // Pipeline stage 1 - Counter management
    reg [3:0] counter_stage1;
    reg [3:0] period_stage1;
    reg cycle_complete_stage1;
    
    // Pipeline stage 2 - Clock toggle decision
    reg [3:0] period_stage2;
    reg direction_stage2;
    reg toggle_clock_stage2;
    reg clock_out_stage2;
    reg enable_spread_stage2;
    reg [3:0] spread_amount_stage2;
    
    // Pipeline stage 3 - Period update
    reg [3:0] period_stage3;
    reg direction_stage3;
    
    // AXI-Stream interface control registers
    reg clock_out;
    reg output_valid;
    reg input_ready;
    
    // AXI-Stream handshaking logic
    always @(posedge aclk or posedge reset) begin
        if (reset) begin
            input_ready <= 1'b1;
            output_valid <= 1'b0;
        end else begin
            // Always ready to accept new control settings
            input_ready <= 1'b1;
            
            // Output valid when processing is complete
            output_valid <= 1'b1;
        end
    end
    
    // Connect AXI-Stream interface signals
    assign s_axis_tready = input_ready;
    assign m_axis_tvalid = output_valid;
    assign m_axis_tdata = clock_out;
    
    // Stage 1: Counter management with Carry Lookahead Adder
    wire [3:0] counter_next;
    wire dummy_cout;
    
    // Carry Lookahead Adder implementation for counter increment
    wire [3:0] g; // Generate signals
    wire [3:0] p; // Propagate signals
    wire [4:0] c; // Carry signals (including c0)
    
    // Generate and propagate signals
    assign g = counter_stage1 & 4'b0001; // Generate happens when counter bit is 1 and increment bit is 1
    assign p = counter_stage1 | 4'b0001; // Propagate happens when either counter bit or increment bit is 1
    
    // Carry calculation using lookahead logic
    assign c[0] = 1'b0; // No initial carry
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // Sum calculation
    assign counter_next = counter_stage1 ^ 4'b0001 ^ {c[3:0]};
    assign dummy_cout = c[4]; // Unused carry out
    
    always @(posedge aclk or posedge reset) begin
        if (reset) begin
            counter_stage1 <= 4'b0;
            period_stage1 <= 4'd8;
            cycle_complete_stage1 <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            if (counter_stage1 >= period_stage1) begin
                counter_stage1 <= 4'b0;
                cycle_complete_stage1 <= 1'b1;
            end else begin
                counter_stage1 <= counter_next;
                cycle_complete_stage1 <= 1'b0;
            end
            
            // Forward period from stage 3 back to stage 1
            period_stage1 <= period_stage3;
        end
    end
    
    // Stage 2: Clock toggle and direction decision
    always @(posedge aclk or posedge reset) begin
        if (reset) begin
            toggle_clock_stage2 <= 1'b0;
            clock_out_stage2 <= 1'b0;
            direction_stage2 <= 1'b0;
            period_stage2 <= 4'd8;
            enable_spread_stage2 <= 1'b0;
            spread_amount_stage2 <= 4'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            // Register inputs for pipeline stage 2
            enable_spread_stage2 <= enable_spread;
            spread_amount_stage2 <= spread_amount;
            
            // Pass period value through pipeline
            period_stage2 <= period_stage1;
            
            // Determine if clock should toggle
            toggle_clock_stage2 <= cycle_complete_stage1;
            
            if (toggle_clock_stage2 && m_axis_tready)
                clock_out_stage2 <= ~clock_out_stage2;
            
            // Direction is passed through from stage 3
            direction_stage2 <= direction_stage3;
        end
    end
    
    // Stage 3: Period update logic with Carry Lookahead Adder
    wire [3:0] period_inc, period_dec;
    wire dummy_inc_cout, dummy_dec_cout;
    
    // Carry Lookahead Adder for period increment (period + 1)
    wire [3:0] g_inc, p_inc;
    wire [4:0] c_inc;
    
    assign g_inc = period_stage2 & 4'b0001;
    assign p_inc = period_stage2 | 4'b0001;
    
    assign c_inc[0] = 1'b0;
    assign c_inc[1] = g_inc[0] | (p_inc[0] & c_inc[0]);
    assign c_inc[2] = g_inc[1] | (p_inc[1] & g_inc[0]) | (p_inc[1] & p_inc[0] & c_inc[0]);
    assign c_inc[3] = g_inc[2] | (p_inc[2] & g_inc[1]) | (p_inc[2] & p_inc[1] & g_inc[0]) | (p_inc[2] & p_inc[1] & p_inc[0] & c_inc[0]);
    assign c_inc[4] = g_inc[3] | (p_inc[3] & g_inc[2]) | (p_inc[3] & p_inc[2] & g_inc[1]) | (p_inc[3] & p_inc[2] & p_inc[1] & g_inc[0]) | (p_inc[3] & p_inc[2] & p_inc[1] & p_inc[0] & c_inc[0]);
    
    assign period_inc = period_stage2 ^ 4'b0001 ^ {c_inc[3:0]};
    assign dummy_inc_cout = c_inc[4];
    
    // Carry Lookahead Adder for period decrement (period - 1)
    wire [3:0] g_dec, p_dec;
    wire [4:0] c_dec;
    
    // For subtraction (A - B), we use A + ~B + 1
    // Since B is 1, ~B is 1110, and adding 1 gives 1111
    assign g_dec = period_stage2 & 4'b1111;  // Generate when both bits are 1
    assign p_dec = period_stage2 | 4'b1111;  // Propagate when either bit is 1
    
    assign c_dec[0] = 1'b1;  // Initial carry-in for subtraction
    assign c_dec[1] = g_dec[0] | (p_dec[0] & c_dec[0]);
    assign c_dec[2] = g_dec[1] | (p_dec[1] & g_dec[0]) | (p_dec[1] & p_dec[0] & c_dec[0]);
    assign c_dec[3] = g_dec[2] | (p_dec[2] & g_dec[1]) | (p_dec[2] & p_dec[1] & g_dec[0]) | (p_dec[2] & p_dec[1] & p_dec[0] & c_dec[0]);
    assign c_dec[4] = g_dec[3] | (p_dec[3] & g_dec[2]) | (p_dec[3] & p_dec[2] & g_dec[1]) | (p_dec[3] & p_dec[2] & p_dec[1] & g_dec[0]) | (p_dec[3] & p_dec[2] & p_dec[1] & p_dec[0] & c_dec[0]);
    
    assign period_dec = period_stage2 ^ 4'b1111 ^ {c_dec[3:0]};
    assign dummy_dec_cout = c_dec[4];
    
    always @(posedge aclk or posedge reset) begin
        if (reset) begin
            period_stage3 <= 4'd8;
            direction_stage3 <= 1'b0;
            clock_out <= 1'b0;
        end else if (m_axis_tready) begin
            // Update the actual clock output
            clock_out <= clock_out_stage2;
            
            // Update period for next half-cycle when clock toggles
            if (toggle_clock_stage2 && enable_spread_stage2) begin
                if (direction_stage2) begin
                    if (period_stage2 < 4'd8 + spread_amount_stage2)
                        period_stage3 <= period_inc;
                    else
                        direction_stage3 <= 1'b0;
                end else begin
                    if (period_stage2 > 4'd8 - spread_amount_stage2)
                        period_stage3 <= period_dec;
                    else
                        direction_stage3 <= 1'b1;
                end
            end else if (toggle_clock_stage2 && !enable_spread_stage2) begin
                period_stage3 <= 4'd8;
            end else begin
                period_stage3 <= period_stage2;
                direction_stage3 <= direction_stage2;
            end
        end
    end
endmodule