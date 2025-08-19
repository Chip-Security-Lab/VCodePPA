module int_ctrl_weighted #(
    parameter N = 4
)(
    input clk, rst,
    input [N*4-1:0] weights,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
    reg [7:0] credit_counter[0:N-1];
    integer i;
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < N; i = i + 1)
                credit_counter[i] <= weights[i*4+:4];
            grant <= 0;
        end else begin
            // Credit update logic
            grant <= 0;
            for(i = 0; i < N; i = i + 1) begin
                if (req[i] && (credit_counter[i] > 0)) begin
                    grant[i] <= 1'b1;
                    credit_counter[i] <= credit_counter[i] - 1'b1;
                end else if (!req[i] && credit_counter[i] < {4'b0, weights[i*4+:4]}) begin
                    credit_counter[i] <= credit_counter[i] + 1'b1;
                end
            end
        end
    end
endmodule