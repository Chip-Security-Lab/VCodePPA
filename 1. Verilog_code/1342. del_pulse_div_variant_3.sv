//SystemVerilog
module del_pulse_div #(parameter N=3) (
    input clk, rst,
    output reg clk_out
);
    // Forward retimed implementation - moving registers downstream
    // Generate and propagate signals
    wire [2:0] g, p, c;
    reg [2:0] next_cnt_reg;
    wire [2:0] next_cnt;
    
    // Generate and propagate calculation
    assign g[0] = next_cnt_reg[0] & 1'b1;     // Generate for bit 0
    assign p[0] = next_cnt_reg[0] ^ 1'b1;     // Propagate for bit 0
    assign g[1] = next_cnt_reg[1] & next_cnt_reg[0];   // Generate for bit 1
    assign p[1] = next_cnt_reg[1] ^ next_cnt_reg[0];   // Propagate for bit 1
    assign g[2] = next_cnt_reg[2] & (g[1] | (p[1] & g[0])); // Generate for bit 2
    assign p[2] = next_cnt_reg[2] ^ (g[1] | (p[1] & g[0])); // Propagate for bit 2
    
    // Carry calculation
    assign c[0] = 1'b1;              // Input carry is 1 for increment
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    
    // Sum calculation
    assign next_cnt[0] = p[0] ^ c[0];
    assign next_cnt[1] = p[1] ^ c[1];
    assign next_cnt[2] = p[2] ^ c[2];
    
    // Retimed control logic - register the next_cnt value first
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            next_cnt_reg <= 3'b000;
        end else begin
            next_cnt_reg <= (next_cnt_reg == N-1) ? 3'b000 : next_cnt;
        end
    end
    
    // Second stage register for clock output
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            clk_out <= 1'b0;
        end else if(next_cnt_reg == N-1) begin
            clk_out <= ~clk_out;
        end
    end
endmodule