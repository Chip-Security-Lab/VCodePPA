//SystemVerilog
module config_timer #(
    parameter DATA_WIDTH = 24,
    parameter PRESCALE_WIDTH = 8,
    parameter LUT_SIZE = 8  // 查找表大小参数
)(
    input clk_i, rst_i, enable_i,
    input [DATA_WIDTH-1:0] period_i,
    input [PRESCALE_WIDTH-1:0] prescaler_i,
    output reg [DATA_WIDTH-1:0] value_o,
    output reg expired_o
);
    // Stage 1: Prescaler counter logic
    reg [PRESCALE_WIDTH-1:0] prescale_counter_stage1;
    reg prescale_tick_stage1;
    reg enable_stage1;
    reg [DATA_WIDTH-1:0] period_stage1;
    reg [DATA_WIDTH-1:0] value_stage1;
    
    // Stage 2: Timer counter logic with parallel prefix subtractor
    reg prescale_tick_stage2;
    reg [DATA_WIDTH-1:0] period_stage2;
    reg [DATA_WIDTH-1:0] value_stage2;
    reg value_update_stage2;
    reg [DATA_WIDTH-1:0] next_value_stage2;
    
    // Parallel prefix subtractor signals
    wire [DATA_WIDTH-1:0] sub_result;
    wire [DATA_WIDTH:0] borrow; // Additional bit for final borrow
    wire valid_sub;
    
    // Stage 3: Expiration detection
    reg [DATA_WIDTH-1:0] value_stage3;
    reg [DATA_WIDTH-1:0] period_stage3;
    reg prescale_tick_stage3;
    
    // Stage 1: Prescaler logic
    always @(posedge clk_i) begin
        if (rst_i) begin
            prescale_counter_stage1 <= 0;
            prescale_tick_stage1 <= 0;
            enable_stage1 <= 0;
            period_stage1 <= 0;
            value_stage1 <= 0;
        end else begin
            enable_stage1 <= enable_i;
            period_stage1 <= period_i;
            value_stage1 <= value_o;
            
            if (enable_i) begin
                if (prescale_counter_stage1 >= prescaler_i) begin
                    prescale_counter_stage1 <= 0;
                    prescale_tick_stage1 <= 1'b1;
                end else begin
                    prescale_counter_stage1 <= prescale_counter_stage1 + 1'b1;
                    prescale_tick_stage1 <= 1'b0;
                end
            end else begin
                prescale_tick_stage1 <= 1'b0;
            end
        end
    end
    
    // Parallel prefix subtractor implementation
    // Generate propagate and generate signals
    wire [DATA_WIDTH-1:0] p, g;
    assign p = value_stage1 ^ period_stage1;
    assign g = (~value_stage1) & period_stage1;
    
    // Level 1 prefix computation (groups of 2)
    wire [DATA_WIDTH-1:0] p_l1, g_l1;
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 2) begin : gen_level1
            if (i+1 < DATA_WIDTH) begin
                assign p_l1[i] = p[i] & p[i+1];
                assign g_l1[i] = g[i] | (p[i] & g[i+1]);
                
                assign p_l1[i+1] = p[i+1];
                assign g_l1[i+1] = g[i+1];
            end else begin
                assign p_l1[i] = p[i];
                assign g_l1[i] = g[i];
            end
        end
    endgenerate
    
    // Level 2 prefix computation (groups of 4)
    wire [DATA_WIDTH-1:0] p_l2, g_l2;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 4) begin : gen_level2
            if (i+2 < DATA_WIDTH) begin
                assign p_l2[i] = p_l1[i] & p_l1[i+2];
                assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i+2]);
                
                if (i+3 < DATA_WIDTH) begin
                    assign p_l2[i+1] = p_l1[i+1] & p_l1[i+3];
                    assign g_l2[i+1] = g_l1[i+1] | (p_l1[i+1] & g_l1[i+3]);
                end else begin
                    assign p_l2[i+1] = p_l1[i+1];
                    assign g_l2[i+1] = g_l1[i+1];
                end
                
                assign p_l2[i+2] = p_l1[i+2];
                assign g_l2[i+2] = g_l1[i+2];
                
                if (i+3 < DATA_WIDTH) begin
                    assign p_l2[i+3] = p_l1[i+3];
                    assign g_l2[i+3] = g_l1[i+3];
                end
            end else begin
                assign p_l2[i] = p_l1[i];
                assign g_l2[i] = g_l1[i];
                if (i+1 < DATA_WIDTH) begin
                    assign p_l2[i+1] = p_l1[i+1];
                    assign g_l2[i+1] = g_l1[i+1];
                end
            end
        end
    endgenerate
    
    // Level 3 prefix computation (groups of 8)
    wire [DATA_WIDTH-1:0] p_l3, g_l3;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 8) begin : gen_level3
            if (i+4 < DATA_WIDTH) begin
                assign p_l3[i] = p_l2[i] & p_l2[i+4];
                assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i+4]);
                
                if (i+5 < DATA_WIDTH) begin
                    assign p_l3[i+1] = p_l2[i+1] & p_l2[i+5];
                    assign g_l3[i+1] = g_l2[i+1] | (p_l2[i+1] & g_l2[i+5]);
                end else begin
                    assign p_l3[i+1] = p_l2[i+1];
                    assign g_l3[i+1] = g_l2[i+1];
                end
                
                if (i+6 < DATA_WIDTH) begin
                    assign p_l3[i+2] = p_l2[i+2] & p_l2[i+6];
                    assign g_l3[i+2] = g_l2[i+2] | (p_l2[i+2] & g_l2[i+6]);
                end else begin
                    assign p_l3[i+2] = p_l2[i+2];
                    assign g_l3[i+2] = g_l2[i+2];
                end
                
                if (i+7 < DATA_WIDTH) begin
                    assign p_l3[i+3] = p_l2[i+3] & p_l2[i+7];
                    assign g_l3[i+3] = g_l2[i+3] | (p_l2[i+3] & g_l2[i+7]);
                end else begin
                    assign p_l3[i+3] = p_l2[i+3];
                    assign g_l3[i+3] = g_l2[i+3];
                end
                
                assign p_l3[i+4] = p_l2[i+4];
                assign g_l3[i+4] = g_l2[i+4];
                
                if (i+5 < DATA_WIDTH) begin
                    assign p_l3[i+5] = p_l2[i+5];
                    assign g_l3[i+5] = g_l2[i+5];
                end
                
                if (i+6 < DATA_WIDTH) begin
                    assign p_l3[i+6] = p_l2[i+6];
                    assign g_l3[i+6] = g_l2[i+6];
                end
                
                if (i+7 < DATA_WIDTH) begin
                    assign p_l3[i+7] = p_l2[i+7];
                    assign g_l3[i+7] = g_l2[i+7];
                end
            end else begin
                // Handle remaining bits
                for (i = i; i < DATA_WIDTH; i = i + 1) begin : gen_remain_l3
                    assign p_l3[i] = p_l2[i];
                    assign g_l3[i] = g_l2[i];
                end
            end
        end
    endgenerate
    
    // Compute final borrows (for 24-bit specifically)
    assign borrow[0] = 1'b0; // No initial borrow
    assign borrow[1] = g[0] | (p[0] & borrow[0]);
    
    generate
        for (i = 1; i < DATA_WIDTH; i = i + 1) begin : gen_borrow
            if (i == 1 || i == 2 || i == 4 || i == 8 || i == 16) begin
                // Use direct computed prefix values at specific positions
                if (i == 1) assign borrow[i+1] = g_l1[i-1];
                else if (i == 2) assign borrow[i+1] = g_l2[i-1];
                else if (i == 4) assign borrow[i+1] = g_l2[i-1];
                else if (i == 8) assign borrow[i+1] = g_l3[i-1];
                else if (i == 16) assign borrow[i+1] = g_l3[i-1];
            end else begin
                // Use local propagate and previous borrow
                assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
            end
        end
    endgenerate
    
    // Compute result
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_result
            assign sub_result[i] = p[i] ^ borrow[i];
        end
    endgenerate
    
    // Check if value_stage1 >= period_stage1
    assign valid_sub = ~borrow[DATA_WIDTH];
    
    // Stage 2: Value counter logic with parallel prefix comparison
    always @(posedge clk_i) begin
        if (rst_i) begin
            prescale_tick_stage2 <= 0;
            period_stage2 <= 0;
            value_stage2 <= 0;
            value_update_stage2 <= 0;
            next_value_stage2 <= 0;
        end else begin
            prescale_tick_stage2 <= prescale_tick_stage1;
            period_stage2 <= period_stage1;
            value_stage2 <= value_stage1;
            
            if (prescale_tick_stage1 && enable_stage1) begin
                value_update_stage2 <= 1'b1;
                if (valid_sub) begin
                    next_value_stage2 <= 0;
                end else begin
                    next_value_stage2 <= value_stage1 + 1'b1;
                end
            end else begin
                value_update_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Expiration detection and output updates
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_stage3 <= 0;
            period_stage3 <= 0;
            prescale_tick_stage3 <= 0;
            value_o <= 0;
            expired_o <= 0;
        end else begin
            value_stage3 <= value_stage2;
            period_stage3 <= period_stage2;
            prescale_tick_stage3 <= prescale_tick_stage2;
            
            if (value_update_stage2) begin
                value_o <= next_value_stage2;
            end
            
            // Parallelized equality check
            if (value_stage2 == period_stage2 && prescale_tick_stage2) begin
                expired_o <= 1'b1;
            end else begin
                expired_o <= 1'b0;
            end
        end
    end
endmodule