//SystemVerilog
module prescaled_timer (
    input wire i_clk, i_arst, i_enable,
    input wire [7:0] i_prescale,
    input wire [15:0] i_max,
    output reg [15:0] o_count,
    output reg o_match
);
    // Register input signals to improve timing at module boundary
    reg i_enable_reg;
    reg [7:0] i_prescale_reg;
    reg [15:0] i_max_reg;
    
    // Input registering
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            i_enable_reg <= 1'b0;
            i_prescale_reg <= 8'd0;
            i_max_reg <= 16'd0;
        end else begin
            i_enable_reg <= i_enable;
            i_prescale_reg <= i_prescale;
            i_max_reg <= i_max;
        end
    end
    
    // Prescaler counter with direct combinational output
    reg [7:0] pre_cnt;
    wire pre_tick;
    
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) 
            pre_cnt <= 8'd0;
        else if (i_enable_reg) 
            pre_cnt <= (pre_cnt >= i_prescale_reg) ? 8'd0 : pre_cnt + 8'd1;
    end
    
    // Generate prescaler tick directly from combinational logic
    // Removed pre_tick_reg to reduce latency in the datapath
    assign pre_tick = (pre_cnt == i_prescale_reg) && i_enable_reg;
    
    // Main counter logic with optimized path
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) 
            o_count <= 16'd0;
        else if (pre_tick) begin
            if (o_count >= i_max_reg)
                o_count <= 16'd0;
            else
                o_count <= o_count + 16'd1;
        end
    end
    
    // Match signal generation with optimized direct comparison
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst)
            o_match <= 1'b0;
        else
            o_match <= (o_count == i_max_reg) || (o_count >= i_max_reg && pre_tick);
    end
    
endmodule