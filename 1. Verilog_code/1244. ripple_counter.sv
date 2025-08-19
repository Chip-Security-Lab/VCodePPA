module ripple_counter (
    input wire clk, rst_n,
    output wire [3:0] q
);
    reg [3:0] q_internal;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q_internal[0] <= 1'b0;
        else
            q_internal[0] <= ~q_internal[0];
    end
    
    genvar i;
    generate
        for (i = 1; i < 4; i = i + 1) begin: ripple_stages
            always @(posedge q_internal[i-1] or negedge rst_n) begin
                if (!rst_n)
                    q_internal[i] <= 1'b0;
                else
                    q_internal[i] <= ~q_internal[i];
            end
        end
    endgenerate
    
    assign q = q_internal;
endmodule