//SystemVerilog
module manchester_decoder (
    input  wire        clk,           // Oversampling clock (4x data rate)
    input  wire        rst_n,
    input  wire        manchester_in,
    input  wire        polarity,      // 0=rising=1, 1=falling=0
    output reg         data_out,
    output reg         data_valid,
    output reg         clock_recovered
);
    reg [1:0] state;
    reg [1:0] sample_cnt;
    reg prev_sample;
    
    // Brent-Kung adder signals
    wire [1:0] sample_cnt_next;
    wire [1:0] g, p;
    wire [1:0] carry;
    
    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
    // Brent-Kung adder implementation for 2-bit counter
    // Generate and propagate signals
    assign g[0] = sample_cnt[0] & 1'b1;
    assign p[0] = sample_cnt[0] ^ 1'b1;
    
    assign g[1] = sample_cnt[1] & 1'b0;
    assign p[1] = sample_cnt[1] ^ 1'b0;
    
    // Carry computation
    assign carry[0] = g[0];
    assign carry[1] = g[1] | (p[1] & g[0]);
    
    // Sum computation
    assign sample_cnt_next[0] = p[0] ^ 1'b0;
    assign sample_cnt_next[1] = p[1] ^ carry[0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sample_cnt <= 2'b00;
            data_out <= 1'b0;
            data_valid <= 1'b0;
            clock_recovered <= 1'b0;
            prev_sample <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            prev_sample <= manchester_in;
            
            if (state == IDLE && manchester_in != prev_sample) begin
                state <= FIRST_HALF;
                sample_cnt <= 2'b00;
            end else if (state == FIRST_HALF && sample_cnt == 2'b01) begin
                state <= SECOND_HALF;
                data_out <= polarity ? ~manchester_in : manchester_in;
                clock_recovered <= 1'b1;
            end else if (state == FIRST_HALF) begin
                sample_cnt <= sample_cnt_next;
            end else if (state == SECOND_HALF && sample_cnt == 2'b01) begin
                state <= FIRST_HALF;
                data_valid <= 1'b1;
                sample_cnt <= 2'b00;
            end else if (state == SECOND_HALF) begin
                sample_cnt <= sample_cnt_next;
            end else begin
                state <= IDLE;
            end
        end
    end
endmodule