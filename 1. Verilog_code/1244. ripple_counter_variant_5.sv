//SystemVerilog
module ripple_counter (
    input wire clk, rst_n,
    output wire [3:0] q
);
    reg [3:0] q_internal;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_internal <= 4'b0000;
        end else begin
            q_internal[0] <= ~q_internal[0];
            
            if (q_internal[0]) begin
                q_internal[1] <= ~q_internal[1];
            end else begin
                q_internal[1] <= q_internal[1];
            end
            
            if (q_internal[0] && q_internal[1]) begin
                q_internal[2] <= ~q_internal[2];
            end else begin
                q_internal[2] <= q_internal[2];
            end
            
            if (q_internal[0] && q_internal[1] && q_internal[2]) begin
                q_internal[3] <= ~q_internal[3];
            end else begin
                q_internal[3] <= q_internal[3];
            end
        end
    end
    
    assign q = q_internal;
endmodule