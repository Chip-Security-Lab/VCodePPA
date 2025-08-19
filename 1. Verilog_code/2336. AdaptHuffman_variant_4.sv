//SystemVerilog
module AdaptHuffman (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
    reg [31:0] freq [0:255];
    reg [7:0] data_reg; // Register to capture input data
    
    // Buffered signals for high fan-out reduction
    reg [31:0] freq_buf1 [0:127];
    reg [31:0] freq_buf2 [0:127];
    
    // Distributed high fan-out control signals
    reg [5:0] level_buf1, level_buf2;
    reg reset_buf1, reset_buf2, reset_buf3, reset_buf4;
    
    integer i;

    initial begin
        for(i=0; i<256; i=i+1)
            freq[i] = 0;
    end

    // Register input data to improve timing
    always @(posedge clk) begin
        data_reg <= data;
    end
    
    // Buffer reset signal to reduce fan-out
    always @(posedge clk) begin
        reset_buf1 <= !rst_n;
        reset_buf2 <= reset_buf1;
        reset_buf3 <= reset_buf1;
        reset_buf4 <= reset_buf2;
    end

    // Kogge-Stone adder implementation
    function [31:0] kogge_stone_add;
        input [31:0] a;
        input [31:0] b;
        
        reg [31:0] p[0:5]; // propagate signals
        reg [31:0] g[0:5]; // generate signals
        reg [31:0] p_buf[0:5][0:1]; // Buffered propagate signals
        reg [31:0] g_buf[0:5][0:1]; // Buffered generate signals
        integer level;
        
        begin
            // Initial P and G values
            p[0] = a ^ b;
            g[0] = a & b;
            
            // Buffer initial values
            p_buf[0][0] = p[0];
            p_buf[0][1] = p[0];
            g_buf[0][0] = g[0];
            g_buf[0][1] = g[0];
            
            // Kogge-Stone parallel prefix computation
            for (level = 1; level < 6; level = level + 1) begin
                g[level] = g_buf[level-1][0];
                p[level] = p_buf[level-1][0];
                
                case (level)
                    1: begin // Level 1: span 1
                        g[level][31:1] = g[level][31:1] | (p[level][31:1] & g[level][30:0]);
                        p[level][31:1] = p[level][31:1] & p[level][30:0];
                    end
                    2: begin // Level 2: span 2
                        g[level][31:2] = g[level][31:2] | (p[level][31:2] & g[level][29:0]);
                        p[level][31:2] = p[level][31:2] & p[level][29:0];
                    end
                    3: begin // Level 3: span 4
                        g[level][31:4] = g[level][31:4] | (p[level][31:4] & g[level][27:0]);
                        p[level][31:4] = p[level][31:4] & p[level][27:0];
                    end
                    4: begin // Level 4: span 8
                        g[level][31:8] = g[level][31:8] | (p[level][31:8] & g[level][23:0]);
                        p[level][31:8] = p[level][31:8] & p[level][23:0];
                    end
                    5: begin // Level 5: span 16
                        g[level][31:16] = g[level][31:16] | (p[level][31:16] & g[level][15:0]);
                        p[level][31:16] = p[level][31:16] & p[level][15:0];
                    end
                endcase
                
                // Buffer computed values for next level
                p_buf[level][0] = p[level];
                p_buf[level][1] = p[level];
                g_buf[level][0] = g[level];
                g_buf[level][1] = g[level];
            end
            
            // Final sum computation
            kogge_stone_add = p_buf[5][0] ^ {g_buf[5][0][30:0], 1'b0};
        end
    endfunction

    // Split frequency update logic into two parts to reduce fan-out and balance logic
    always @(posedge clk) begin
        if (reset_buf3) begin
            for(i=0; i<128; i=i+1)
                freq_buf1[i] <= 32'd0;
        end
        else begin
            for(i=0; i<128; i=i+1)
                freq_buf1[i] <= (i == data_reg) ? kogge_stone_add(freq[i], 32'd1) : freq[i];
        end
    end
    
    always @(posedge clk) begin
        if (reset_buf4) begin
            for(i=0; i<128; i=i+1)
                freq_buf2[i] <= 32'd0;
        end
        else begin
            for(i=0; i<128; i=i+1)
                freq_buf2[i] <= ((i+128) == data_reg) ? kogge_stone_add(freq[i+128], 32'd1) : freq[i+128];
        end
    end
    
    // Merge the buffered frequency updates
    always @(posedge clk) begin
        for(i=0; i<128; i=i+1)
            freq[i] <= freq_buf1[i];
        for(i=0; i<128; i=i+1)
            freq[i+128] <= freq_buf2[i];
            
        code <= reset_buf2 ? 16'd0 : freq[data_reg][15:0];
    end
endmodule