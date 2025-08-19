//SystemVerilog
module int_ctrl_weighted #(
    parameter N = 4
)(
    input clk, rst,
    input [N*4-1:0] weights,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
    reg [7:0] credit_counter[0:N-1];
    reg [3:0] weight_cache[0:N-1];
    integer i;
    
    always @(posedge clk) begin
        if(rst) begin
            grant <= {N{1'b0}};
            for(i = 0; i < N; i = i + 1) begin
                credit_counter[i] <= weights[i*4+:4];
                weight_cache[i] <= weights[i*4+:4];
            end
        end else begin
            grant <= {N{1'b0}};
            for(i = 0; i < N; i = i + 1) begin
                if (req[i]) begin
                    if (|credit_counter[i][7:0]) begin
                        grant[i] <= 1'b1;
                        credit_counter[i] <= credit_counter[i] - 8'd1;
                    end
                end else begin
                    if (credit_counter[i] < {4'b0, weight_cache[i]}) begin
                        credit_counter[i] <= credit_counter[i] + 8'd1;
                    end
                end
            end
        end
    end
endmodule