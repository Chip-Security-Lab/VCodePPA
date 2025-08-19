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
    reg [1:0] next_state;
    reg [1:0] sample_cnt;
    reg [1:0] next_sample_cnt;
    reg prev_sample;
    reg next_prev_sample;
    reg next_data_out;
    reg next_data_valid;
    reg next_clock_recovered;
    
    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
    // Combinational logic
    always @(*) begin
        next_state = state;
        next_sample_cnt = sample_cnt;
        next_prev_sample = manchester_in;
        next_data_out = data_out;
        next_data_valid = 1'b0;
        next_clock_recovered = 1'b0;
        
        case (state)
            IDLE: begin
                if (manchester_in != prev_sample) begin
                    next_state = FIRST_HALF;
                    next_sample_cnt = 2'b00;
                end
            end
            
            FIRST_HALF: begin
                if (sample_cnt == 2'b01) begin
                    next_state = SECOND_HALF;
                    next_data_out = polarity ? ~manchester_in : manchester_in;
                    next_clock_recovered = 1'b1;
                end else
                    next_sample_cnt = sample_cnt + 1'b1;
            end
            
            SECOND_HALF: begin
                if (sample_cnt == 2'b01) begin
                    next_state = FIRST_HALF;
                    next_data_valid = 1'b1;
                    next_sample_cnt = 2'b00;
                end else
                    next_sample_cnt = sample_cnt + 1'b1;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sample_cnt <= 2'b00;
            data_out <= 1'b0;
            data_valid <= 1'b0;
            clock_recovered <= 1'b0;
            prev_sample <= 1'b0;
        end else begin
            state <= next_state;
            sample_cnt <= next_sample_cnt;
            prev_sample <= next_prev_sample;
            data_out <= next_data_out;
            data_valid <= next_data_valid;
            clock_recovered <= next_clock_recovered;
        end
    end
endmodule