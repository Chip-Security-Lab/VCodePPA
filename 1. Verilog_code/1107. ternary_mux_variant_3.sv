//SystemVerilog
module ternary_mux (
    input wire              clk,             // Clock for pipelining
    input wire              rst_n,           // Active low reset
    input wire [1:0]        selector,        // Selection control
    input wire [7:0]        input_a, 
    input wire [7:0]        input_b, 
    input wire [7:0]        input_c, 
    input wire [7:0]        input_d,         // Input data signals
    output wire [7:0]       mux_out          // Output result
);

    // Stage 1: Register selector and inputs, and perform multiplexing in the same stage
    reg [7:0] mux_result_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_result_stage1 <= 8'd0;
        end else begin
            case (selector)
                2'b00: mux_result_stage1 <= input_a;
                2'b01: mux_result_stage1 <= input_b;
                2'b10: mux_result_stage1 <= input_c;
                default: mux_result_stage1 <= input_d;
            endcase
        end
    end

    // Stage 2: Output register for final mux output
    reg [7:0] mux_out_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mux_out_stage2 <= 8'd0;
        else
            mux_out_stage2 <= mux_result_stage1;
    end

    assign mux_out = mux_out_stage2;

endmodule