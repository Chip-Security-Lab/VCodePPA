//SystemVerilog
module nor2_param (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  A,
    input  wire [1:0]  B,
    output wire [1:0]  Y
);

// Stage 1: Input Registering
reg [1:0] A_stage1;
reg [1:0] B_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_stage1 <= 2'b0;
        B_stage1 <= 2'b0;
    end else begin
        A_stage1 <= A;
        B_stage1 <= B;
    end
end

// Stage 2: OR operation, registered
reg [1:0] or_result_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        or_result_stage2 <= 2'b0;
    end else begin
        or_result_stage2 <= A_stage1 | B_stage1;
    end
end

// Stage 3: NOR operation, output register
reg [1:0] Y_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Y_stage3 <= 2'b0;
    end else begin
        Y_stage3 <= ~or_result_stage2;
    end
end

assign Y = Y_stage3;

endmodule