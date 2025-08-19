module poly1305_mac #(parameter WIDTH = 32) (
    input wire clk, reset_n,
    input wire update, finalize,
    input wire [WIDTH-1:0] r_key, s_key, data_in,
    output reg [WIDTH-1:0] mac_out,
    output reg ready, mac_valid
);
    reg [WIDTH-1:0] accumulator, r;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam ACCUMULATE = 2'b01;
    localparam FINAL = 2'b10;
    
    // Simplified polynomial calculation (real Poly1305 is more complex)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            accumulator <= 0;
            r <= 0;
            state <= IDLE;
            ready <= 1;
            mac_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (update && ready) begin
                        r <= r_key & 32'h0FFFFFFF; // Mask off top bits as in Poly1305
                        accumulator <= 0;
                        state <= ACCUMULATE;
                        ready <= 0;
                    end
                end
                ACCUMULATE: begin
                    if (update) begin
                        // Add data and multiply by r (simplified)
                        accumulator <= ((accumulator + data_in) * r) % (2**WIDTH - 5);
                    end else if (finalize) begin
                        state <= FINAL;
                    end else ready <= 1;
                end
                FINAL: begin
                    mac_out <= (accumulator + s_key) % (2**WIDTH);
                    mac_valid <= 1;
                    state <= IDLE;
                    ready <= 1;
                end
            endcase
        end
    end
endmodule