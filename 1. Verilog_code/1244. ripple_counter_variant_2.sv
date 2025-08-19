//SystemVerilog
module ripple_counter (
    input wire clk, rst_n,
    output reg [3:0] q
);
    // Internal synchronization signals
    reg [2:0] sync_clk;
    
    // First bit toggle with main clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q[0] <= 1'b0;
        else
            q[0] <= ~q[0];
    end
    
    // Generate synchronized clock signals - moving registers backward through logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_clk[0] <= 1'b0;
            sync_clk[1] <= 1'b0;
            sync_clk[2] <= 1'b0;
        end
        else begin
            sync_clk[0] <= q[0];
            sync_clk[1] <= sync_clk[0] & ~q[1];
            sync_clk[2] <= sync_clk[1] & ~q[2];
        end
    end
    
    // Retimed counter bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q[1] <= 1'b0;
            q[2] <= 1'b0;
            q[3] <= 1'b0;
        end
        else begin
            if (q[0] & ~sync_clk[0])
                q[1] <= ~q[1];
                
            if (sync_clk[0] & ~sync_clk[1])
                q[2] <= ~q[2];
                
            if (sync_clk[1] & ~sync_clk[2])
                q[3] <= ~q[3];
        end
    end
endmodule