//SystemVerilog
module ones_comp #(parameter WIDTH=8) (
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_in,
    input                   data_in_valid,
    output [WIDTH-1:0]      data_out,
    output                  data_out_valid
);

    // Stage 1: Input Register
    reg [WIDTH-1:0] data_stage1_reg;
    reg             data_stage1_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1_reg   <= {WIDTH{1'b0}};
            data_stage1_valid <= 1'b0;
        end else begin
            data_stage1_reg   <= data_in;
            data_stage1_valid <= data_in_valid;
        end
    end

    // Stage 2: Bitwise Invert (Ones' Complement) Pipeline Register
    reg [WIDTH-1:0] data_stage2_reg;
    reg             data_stage2_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2_reg   <= {WIDTH{1'b0}};
            data_stage2_valid <= 1'b0;
        end else begin
            data_stage2_reg   <= ~data_stage1_reg;
            data_stage2_valid <= data_stage1_valid;
        end
    end

    assign data_out       = data_stage2_reg;
    assign data_out_valid = data_stage2_valid;

endmodule