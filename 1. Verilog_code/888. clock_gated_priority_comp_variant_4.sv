//SystemVerilog
//-------------------------------------------------------------------------------
// Top module: Hierarchical clock gated priority encoder
//-------------------------------------------------------------------------------
module clock_gated_priority_comp #(parameter WIDTH = 8)(
    input clk,
    input rst_n,
    input enable,
    input [WIDTH-1:0] data_in,
    output [$clog2(WIDTH)-1:0] priority_out
);
    // Internal signals
    wire gated_clk;
    wire [$clog2(WIDTH)-1:0] priority_value;
    wire [$clog2(WIDTH)-1:0] priority_stage1;
    
    // Clock gating submodule
    clock_gating_cell u_clock_gating (
        .clk(clk),
        .enable(enable),
        .gated_clk(gated_clk)
    );
    
    // Priority encoder submodule with pipelined architecture
    priority_encoder_pipelined #(
        .WIDTH(WIDTH)
    ) u_priority_encoder (
        .clk(gated_clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .priority_stage1(priority_stage1),
        .priority_value(priority_value)
    );
    
    // Output register with reset control
    output_register #(
        .WIDTH($clog2(WIDTH))
    ) u_output_register (
        .clk(gated_clk),
        .rst_n(rst_n),
        .data_in(priority_value),
        .data_out(priority_out)
    );
    
endmodule

//-------------------------------------------------------------------------------
// Clock gating cell submodule
//-------------------------------------------------------------------------------
module clock_gating_cell (
    input clk,
    input enable,
    output gated_clk
);
    reg enable_latch;
    
    // Latch-based clock gating
    always @(clk or enable)
        if (!clk) enable_latch <= enable;
        
    // Gated clock output
    assign gated_clk = clk & enable_latch;
    
endmodule

//-------------------------------------------------------------------------------
// Pipelined Priority encoder submodule
//-------------------------------------------------------------------------------
module priority_encoder_pipelined #(parameter WIDTH = 8)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_stage1,
    output [$clog2(WIDTH)-1:0] priority_value
);
    reg [$clog2(WIDTH)-1:0] encoded_value;
    reg [WIDTH-1:0] data_upper, data_lower;
    reg upper_valid;
    
    // First pipeline stage - split input processing
    // Process upper and lower halves separately to reduce critical path
    always @(*) begin
        data_upper = data_in[WIDTH-1:WIDTH/2];
        data_lower = data_in[WIDTH/2-1:0];
        upper_valid = |data_upper;
        
        // First stage priority encoding - detect if upper half has any set bits
        if (upper_valid) begin
            // Pre-calculate MSB position in upper half
            encoded_value = 0;
            for (integer i = WIDTH-1; i >= WIDTH/2; i = i - 1)
                if (data_in[i]) encoded_value = i[$clog2(WIDTH)-1:0];
        end else begin
            // Pre-calculate MSB position in lower half
            encoded_value = 0;
            for (integer i = WIDTH/2-1; i >= 0; i = i - 1)
                if (data_in[i]) encoded_value = i[$clog2(WIDTH)-1:0];
        end
    end
    
    // Pipeline register to store intermediate results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_stage1 <= 0;
        end else begin
            priority_stage1 <= encoded_value;
        end
    end
    
    // Second pipeline stage output
    assign priority_value = priority_stage1;
    
endmodule

//-------------------------------------------------------------------------------
// Output register submodule
//-------------------------------------------------------------------------------
module output_register #(parameter WIDTH = 3)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Synchronous register with asynchronous reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
        end else begin
            data_out <= data_in;
        end
    end
    
endmodule