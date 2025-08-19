//SystemVerilog
module ror_module #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst,
    input                   en,
    input  [WIDTH-1:0]      data_in,
    input  [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0]  data_out
);

    // Pipeline Stage 1: Input Registering
    reg [WIDTH-1:0] data_in_stage1;
    reg [$clog2(WIDTH)-1:0] rotate_by_stage1;
    reg en_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_stage1    <= {WIDTH{1'b0}};
            rotate_by_stage1  <= {($clog2(WIDTH)){1'b0}};
            en_stage1         <= 1'b0;
        end else begin
            data_in_stage1    <= data_in;
            rotate_by_stage1  <= rotate_by;
            en_stage1         <= en;
        end
    end

    // Pipeline Stage 2: Double Data Generation and Rotate Index Extension
    reg [2*WIDTH-1:0] double_data_stage2;
    reg [WIDTH-1:0] rotate_by_ext_stage2;
    reg en_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            double_data_stage2   <= {(2*WIDTH){1'b0}};
            rotate_by_ext_stage2 <= {WIDTH{1'b0}};
            en_stage2            <= 1'b0;
        end else begin
            double_data_stage2   <= {data_in_stage1, data_in_stage1};
            rotate_by_ext_stage2 <= {{(WIDTH-($clog2(WIDTH))){1'b0}}, rotate_by_stage1};
            en_stage2            <= en_stage1;
        end
    end

    // Pipeline Stage 3: Rotation Logic
    wire [WIDTH-1:0] rotated_result_stage3;
    reg  [WIDTH-1:0] rotated_result_reg_stage3;
    reg en_stage3;

    // Rotation logic: right rotate by rotate_by_ext_stage2
    rotate_right #(
        .WIDTH(WIDTH)
    ) rotate_right_inst (
        .data_in(double_data_stage2[WIDTH-1:0]),
        .rotate_by(rotate_by_ext_stage2[$clog2(WIDTH)-1:0]),
        .data_out(rotated_result_stage3)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rotated_result_reg_stage3 <= {WIDTH{1'b0}};
            en_stage3                 <= 1'b0;
        end else begin
            rotated_result_reg_stage3 <= rotated_result_stage3;
            en_stage3                 <= en_stage2;
        end
    end

    // Pipeline Stage 4: Output Registering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
        end else if (en_stage3) begin
            data_out <= rotated_result_reg_stage3;
        end
    end

endmodule

// Rotate right module with clear data flow and pipelined interface
module rotate_right #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_in,
    input  [$clog2(WIDTH)-1:0] rotate_by,
    output [WIDTH-1:0] data_out
);
    assign data_out = (data_in >> rotate_by) | (data_in << (WIDTH - rotate_by));
endmodule