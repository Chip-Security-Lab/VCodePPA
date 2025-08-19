//SystemVerilog
module MatrixArbiter #(parameter N=4) (
    input clk, rst,
    input [N-1:0] req,
    output [N-1:0] grant
);

// Pipeline stage 1 registers
reg [N-1:0] priority_matrix_stage1 [0:N-1];
reg [1:0] counter_stage1;
reg [N-1:0] req_stage1;

// Pipeline stage 2 registers
reg [N-1:0] priority_matrix_stage2 [0:N-1];
reg [1:0] counter_stage2;
reg [N-1:0] req_stage2;

// Pipeline stage 3 registers
reg [N-1:0] priority_matrix_stage3 [0:N-1];
reg [1:0] counter_stage3;
reg [N-1:0] req_stage3;

// Manchester carry chain signals
wire [1:0] manchester_sum;
wire [1:0] manchester_carry;
wire [1:0] manchester_propagate;
wire [1:0] manchester_generate;

// Grant calculation signals
wire [N-1:0] grant_comb;
reg [N-1:0] grant_reg;

integer i;

// Manchester carry chain implementation for 2-bit counter
assign manchester_propagate[0] = 1'b1;
assign manchester_generate[0] = counter_stage1[0];
assign manchester_carry[0] = manchester_generate[0];

assign manchester_propagate[1] = counter_stage1[0];
assign manchester_generate[1] = counter_stage1[1];
assign manchester_carry[1] = manchester_generate[1] | (manchester_propagate[1] & manchester_carry[0]);

assign manchester_sum[0] = counter_stage1[0] ^ 1'b1;
assign manchester_sum[1] = counter_stage1[1] ^ manchester_carry[0];

// Stage 1: Input capture and initial processing
always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1)
            priority_matrix_stage1[i] <= 0;
        counter_stage1 <= 0;
        req_stage1 <= 0;
    end else begin
        req_stage1 <= req;
        for(i=N-1; i>0; i=i-1)
            priority_matrix_stage1[i] <= priority_matrix_stage1[i-1];
        priority_matrix_stage1[0] <= req;
        counter_stage1 <= manchester_sum;
    end
end

// Stage 2: Matrix processing
always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1)
            priority_matrix_stage2[i] <= 0;
        counter_stage2 <= 0;
        req_stage2 <= 0;
    end else begin
        req_stage2 <= req_stage1;
        for(i=0; i<N; i=i+1)
            priority_matrix_stage2[i] <= priority_matrix_stage1[i];
        counter_stage2 <= counter_stage1;
    end
end

// Stage 3: Grant calculation
always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1)
            priority_matrix_stage3[i] <= 0;
        counter_stage3 <= 0;
        req_stage3 <= 0;
        grant_reg <= 0;
    end else begin
        req_stage3 <= req_stage2;
        for(i=0; i<N; i=i+1)
            priority_matrix_stage3[i] <= priority_matrix_stage2[i];
        counter_stage3 <= counter_stage2;
        grant_reg <= grant_comb;
    end
end

// Combinational grant calculation
assign grant_comb = req_stage3 & priority_matrix_stage3[counter_stage3];

// Output stage with registered grant
assign grant = grant_reg;

endmodule