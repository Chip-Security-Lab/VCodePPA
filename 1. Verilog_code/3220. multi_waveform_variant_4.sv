//SystemVerilog
module multi_waveform(
    input clk,
    input rst_n,
    input [1:0] wave_sel,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    reg direction;
    wire [7:0] counter_next;
    wire [7:0] triangle_wave;
    wire [7:0] staircase_wave;
    
    // Carry Lookahead Adder for counter increment
    wire [7:0] g, p;
    wire [7:0] c;
    
    // Generate and Propagate signals
    assign g = counter & 8'h01;
    assign p = counter ^ 8'h01;
    
    // Carry computation
    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    
    // Sum computation
    assign counter_next = p ^ c;
    
    // Triangle wave computation using CLA
    wire [7:0] triangle_g, triangle_p;
    wire [7:0] triangle_c;
    
    assign triangle_g = counter & 8'h01;
    assign triangle_p = counter ^ 8'h01;
    
    assign triangle_c[0] = 1'b0;
    assign triangle_c[1] = triangle_g[0] | (triangle_p[0] & triangle_c[0]);
    assign triangle_c[2] = triangle_g[1] | (triangle_p[1] & triangle_c[1]);
    assign triangle_c[3] = triangle_g[2] | (triangle_p[2] & triangle_c[2]);
    assign triangle_c[4] = triangle_g[3] | (triangle_p[3] & triangle_c[3]);
    assign triangle_c[5] = triangle_g[4] | (triangle_p[4] & triangle_c[4]);
    assign triangle_c[6] = triangle_g[5] | (triangle_p[5] & triangle_c[5]);
    assign triangle_c[7] = triangle_g[6] | (triangle_p[6] & triangle_c[6]);
    
    assign triangle_wave = direction ? (8'd255 - (triangle_p ^ triangle_c)) : (triangle_p ^ triangle_c);
    
    // Staircase wave computation
    assign staircase_wave = {counter[7:2], 2'b00};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            direction <= 1'b0;
            wave_out <= 8'd0;
        end else begin
            counter <= counter_next;
            
            case (wave_sel)
                2'b00: // Square wave
                    wave_out <= (counter < 8'd128) ? 8'd255 : 8'd0;
                2'b01: // Sawtooth wave
                    wave_out <= counter;
                2'b10: begin // Triangle wave
                    if (!direction) begin
                        if (counter == 8'd255) direction <= 1'b1;
                        wave_out <= triangle_wave;
                    end else begin
                        if (counter == 8'd0) direction <= 1'b0;
                        wave_out <= triangle_wave;
                    end
                end
                2'b11: // Staircase wave
                    wave_out <= staircase_wave;
            endcase
        end
    end
endmodule