//SystemVerilog
module ternary_mux (
    input wire             clk,           // Clock for pipelining
    input wire             rst_n,         // Active-low synchronous reset
    input wire [1:0]       selector_in,   // Selection control
    input wire [7:0]       input_a_in, 
    input wire [7:0]       input_b_in, 
    input wire [7:0]       input_c_in, 
    input wire [7:0]       input_d_in,    // Data inputs
    output wire [7:0]      mux_out        // Output result
);

    // Stage 1: Input Registering
    reg [1:0] selector_stage1;
    reg [7:0] input_a_stage1, input_b_stage1, input_c_stage1, input_d_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selector_stage1   <= 2'b00;
            input_a_stage1    <= 8'b0;
            input_b_stage1    <= 8'b0;
            input_c_stage1    <= 8'b0;
            input_d_stage1    <= 8'b0;
        end else begin
            selector_stage1   <= selector_in;
            input_a_stage1    <= input_a_in;
            input_b_stage1    <= input_b_in;
            input_c_stage1    <= input_c_in;
            input_d_stage1    <= input_d_in;
        end
    end

    // Stage 2: Mux Logic
    reg [7:0] mux_data_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_data_stage2 <= 8'b0;
        end else begin
            case (selector_stage1)
                2'b00: mux_data_stage2 <= input_a_stage1;
                2'b01: mux_data_stage2 <= input_b_stage1;
                2'b10: mux_data_stage2 <= input_c_stage1;
                default: mux_data_stage2 <= input_d_stage1;
            endcase
        end
    end

    // Stage 3: Output Registering
    reg [7:0] mux_out_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_stage3 <= 8'b0;
        end else begin
            mux_out_stage3 <= mux_data_stage2;
        end
    end

    assign mux_out = mux_out_stage3;

endmodule