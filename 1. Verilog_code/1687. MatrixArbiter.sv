module MatrixArbiter #(parameter N=4) (
    input clk, rst,
    input [N-1:0] req,
    output [N-1:0] grant
);
reg [N-1:0] priority_matrix [0:N-1];
reg [1:0] counter; // 用确定性选择替代随机选择
integer i;

always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<N; i=i+1)
            priority_matrix[i] <= 0;
        counter <= 0;
    end else begin
        // Shift matrix and append req
        for(i=N-1; i>0; i=i-1)
            priority_matrix[i] <= priority_matrix[i-1];
        priority_matrix[0] <= req;
        
        // Update counter
        counter <= counter + 1;
    end
end

assign grant = req & priority_matrix[counter];
endmodule