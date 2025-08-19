//SystemVerilog
module debounce_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_signal,
    output wire clean_signal
);

    wire sync_out;
    wire [15:0] count_out;
    
    signal_sync sync_inst (
        .clk(clk),
        .async_signal(noisy_signal),
        .sync_signal(sync_out)
    );
    
    debounce_logic debounce_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sync_signal(sync_out),
        .clean_signal(clean_signal),
        .count(count_out)
    );

endmodule

module signal_sync (
    input wire clk,
    input wire async_signal,
    output reg sync_signal
);
    reg sync_1;
    
    always @(posedge clk) begin
        sync_1 <= async_signal;
        sync_signal <= sync_1;
    end
endmodule

module debounce_logic (
    input wire clk,
    input wire rst_n,
    input wire sync_signal,
    output reg clean_signal,
    output reg [15:0] count
);
    wire [15:0] next_count;
    wire [3:0] carry;
    
    cla_adder_16bit adder (
        .a(count),
        .b(16'h0001),
        .cin(1'b0),
        .sum(next_count),
        .cout()
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 16'h0000;
            clean_signal <= 1'b0;
        end else begin
            if (sync_signal != clean_signal) begin
                count <= next_count;
                if (count == 16'hFFFF) begin
                    clean_signal <= sync_signal;
                    count <= 16'h0000;
                end
            end else begin
                count <= 16'h0000;
            end
        end
    end
endmodule

module cla_adder_16bit (
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum,
    output cout
);
    wire [15:0] p, g;
    wire [16:0] c;
    
    assign p = a ^ b;
    assign g = a & b;
    
    assign c[0] = cin;
    
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[4]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c[4]);
    assign c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & c[4]);
    
    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & c[8]);
    assign c[11] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | (p[10] & p[9] & p[8] & c[8]);
    assign c[12] = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]) | (p[11] & p[10] & p[9] & p[8] & c[8]);
    
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & c[12]);
    assign c[15] = g[14] | (p[14] & g[13]) | (p[14] & p[13] & g[12]) | (p[14] & p[13] & p[12] & c[12]);
    assign c[16] = g[15] | (p[15] & g[14]) | (p[15] & p[14] & g[13]) | (p[15] & p[14] & p[13] & g[12]) | (p[15] & p[14] & p[13] & p[12] & c[12]);
    
    assign sum = p ^ c[15:0];
    assign cout = c[16];
endmodule