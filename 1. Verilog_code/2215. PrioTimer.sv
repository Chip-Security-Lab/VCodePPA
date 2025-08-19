module PrioTimer #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [$clog2(N)-1:0] grant
);
    reg [7:0] cnt [0:N-1];
    integer i;
    
    always @(posedge clk) begin
        for(i=0; i<N; i=i+1)
            if (!rst_n)
                cnt[i] <= 8'h00;
            else if(req[i])
                cnt[i] <= cnt[i] + 8'h01;
        
        grant <= {$clog2(N){1'b0}}; // 默认值
        for(i=N-1; i>=0; i=i-1)
            if(cnt[i] > 8'h7F) grant <= i[$clog2(N)-1:0];
    end
endmodule