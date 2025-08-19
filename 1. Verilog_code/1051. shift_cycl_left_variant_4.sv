//SystemVerilog
module shift_cycl_left_pipeline #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,
    output reg valid_out
);

    // Stage 1: Input register and valid
    reg [WIDTH-1:0] data_in_stage1;
    reg             valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {WIDTH{1'b0}};
            valid_stage1   <= 1'b0;
        end else if (en) begin
            data_in_stage1 <= data_in;
            valid_stage1   <= 1'b1;
        end else begin
            valid_stage1   <= 1'b0;
        end
    end

    // Stage 2: Rotate logic and register, valid propagation
    wire [WIDTH-1:0] rotated_data_stage2;
    assign rotated_data_stage2 = (WIDTH > 1) ? {data_in_stage1[WIDTH-2:0], data_in_stage1[WIDTH-1]} : data_in_stage1;

    reg [WIDTH-1:0] data_out_stage2;
    reg             valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage2 <= {WIDTH{1'b0}};
            valid_stage2    <= 1'b0;
        end else begin
            data_out_stage2 <= rotated_data_stage2;
            valid_stage2    <= valid_stage1;
        end
    end

    // Output register stage, optional for further pipelining and to ensure timing closure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out  <= data_out_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule