//SystemVerilog
module MatrixArbiter #(parameter N=4) (
    input clk, rst,
    input [N-1:0] req,
    output [N-1:0] grant
);

wire [N-1:0] priority_matrix [0:N-1];
wire [1:0] counter;

PriorityMatrix #(.N(N)) u_priority_matrix (
    .clk(clk),
    .rst(rst),
    .req(req),
    .priority_matrix(priority_matrix)
);

Counter #(.N(N)) u_counter (
    .clk(clk),
    .rst(rst),
    .counter(counter)
);

GrantLogic #(.N(N)) u_grant_logic (
    .req(req),
    .priority_matrix(priority_matrix),
    .counter(counter),
    .grant(grant)
);

endmodule

module PriorityMatrix #(parameter N=4) (
    input clk, rst,
    input [N-1:0] req,
    output reg [N-1:0] priority_matrix [0:N-1]
);

integer i;

always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1)
            priority_matrix[i] <= 0;
    end else begin
        for(i=N-1; i>0; i=i-1)
            priority_matrix[i] <= priority_matrix[i-1];
        priority_matrix[0] <= req;
    end
end

endmodule

module Counter #(parameter N=4) (
    input clk, rst,
    output reg [1:0] counter
);

always @(posedge clk) begin
    if(rst)
        counter <= 0;
    else
        counter <= counter + 1;
end

endmodule

module GrantLogic #(parameter N=4) (
    input [N-1:0] req,
    input [N-1:0] priority_matrix [0:N-1],
    input [1:0] counter,
    output [N-1:0] grant
);

assign grant = req & priority_matrix[counter];

endmodule