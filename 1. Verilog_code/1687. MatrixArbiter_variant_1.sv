//SystemVerilog
// Priority Matrix Pipeline Stage Module
module PriorityMatrixStage #(parameter N=4) (
    input clk,
    input rst,
    input valid_in,
    input [N-1:0] req_in,
    input [N-1:0] priority_matrix_in [0:N-1],
    input [1:0] counter_in,
    output reg valid_out,
    output reg [N-1:0] req_out,
    output reg [N-1:0] priority_matrix_out [0:N-1],
    output reg [1:0] counter_out
);

integer i;

always @(posedge clk) begin
    if(rst) begin
        valid_out <= 0;
        for(i=0; i<N; i=i+1)
            priority_matrix_out[i] <= 0;
        counter_out <= 0;
        req_out <= 0;
    end else begin
        valid_out <= valid_in;
        for(i=0; i<N; i=i+1)
            priority_matrix_out[i] <= priority_matrix_in[i];
        counter_out <= counter_in;
        req_out <= req_in;
    end
end

endmodule

// Input Stage Module
module InputStage #(parameter N=4) (
    input clk,
    input rst,
    input valid_in,
    input [N-1:0] req_in,
    input [N-1:0] priority_matrix_in [0:N-1],
    input [1:0] counter_in,
    output reg valid_out,
    output reg [N-1:0] req_out,
    output reg [N-1:0] priority_matrix_out [0:N-1],
    output reg [1:0] counter_out
);

integer i;

always @(posedge clk) begin
    if(rst) begin
        valid_out <= 0;
        for(i=0; i<N; i=i+1)
            priority_matrix_out[i] <= 0;
        counter_out <= 0;
        req_out <= 0;
    end else begin
        valid_out <= valid_in;
        for(i=N-1; i>0; i=i-1)
            priority_matrix_out[i] <= priority_matrix_in[i-1];
        priority_matrix_out[0] <= req_in;
        counter_out <= counter_in + 1;
        req_out <= req_in;
    end
end

endmodule

// Grant Calculation Module
module GrantCalculator #(parameter N=4) (
    input valid_in,
    input [N-1:0] req,
    input [N-1:0] priority_matrix [0:N-1],
    input [1:0] counter,
    output reg valid_out,
    output reg [N-1:0] grant
);

always @(*) begin
    if(valid_in) begin
        grant = req & priority_matrix[counter];
        valid_out = 1'b1;
    end else begin
        grant = {N{1'b0}};
        valid_out = 1'b0;
    end
end

endmodule

// Top Level Matrix Arbiter Module
module MatrixArbiter #(parameter N=4) (
    input clk,
    input rst,
    input valid_in,
    input [N-1:0] req,
    output valid_out,
    output [N-1:0] grant
);

// Stage 1 signals
wire [N-1:0] priority_matrix_stage1 [0:N-1];
wire [1:0] counter_stage1;
wire [N-1:0] req_stage1;
wire valid_stage1;

// Stage 2 signals
wire [N-1:0] priority_matrix_stage2 [0:N-1];
wire [1:0] counter_stage2;
wire [N-1:0] req_stage2;
wire valid_stage2;

// Stage 3 signals
wire [N-1:0] priority_matrix_stage3 [0:N-1];
wire [1:0] counter_stage3;
wire [N-1:0] req_stage3;
wire valid_stage3;

// Input Stage Instance
InputStage #(N) input_stage (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .req_in(req),
    .priority_matrix_in(priority_matrix_stage1),
    .counter_in(counter_stage1),
    .valid_out(valid_stage1),
    .req_out(req_stage1),
    .priority_matrix_out(priority_matrix_stage1),
    .counter_out(counter_stage1)
);

// Pipeline Stage 2 Instance
PriorityMatrixStage #(N) stage2 (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_stage1),
    .req_in(req_stage1),
    .priority_matrix_in(priority_matrix_stage1),
    .counter_in(counter_stage1),
    .valid_out(valid_stage2),
    .req_out(req_stage2),
    .priority_matrix_out(priority_matrix_stage2),
    .counter_out(counter_stage2)
);

// Pipeline Stage 3 Instance
PriorityMatrixStage #(N) stage3 (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_stage2),
    .req_in(req_stage2),
    .priority_matrix_in(priority_matrix_stage2),
    .counter_in(counter_stage2),
    .valid_out(valid_stage3),
    .req_out(req_stage3),
    .priority_matrix_out(priority_matrix_stage3),
    .counter_out(counter_stage3)
);

// Grant Calculator Instance
GrantCalculator #(N) grant_calc (
    .valid_in(valid_stage3),
    .req(req_stage3),
    .priority_matrix(priority_matrix_stage3),
    .counter(counter_stage3),
    .valid_out(valid_out),
    .grant(grant)
);

endmodule