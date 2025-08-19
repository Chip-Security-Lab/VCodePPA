//SystemVerilog
// Parameterized sample counter module
module sample_counter #(
    parameter MAX_COUNT = 2
) (
    input  wire clk,
    input  wire rst_n,
    input  wire count_en,
    input  wire reset,
    output reg [1:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 2'b00;
        else if (reset)
            count <= 2'b00;
        else if (count_en)
            count <= count + 1'b1;
    end
endmodule

// State transition logic module
module state_transition_logic (
    input  wire [1:0] current_state,
    input  wire [1:0] sample_cnt,
    input  wire manchester_in,
    input  wire prev_sample,
    input  wire polarity,
    output reg [1:0] next_state,
    output reg next_data_out,
    output reg next_data_valid,
    output reg next_clock_recovered,
    output reg next_sample_cnt_reset,
    output reg next_sample_cnt_en
);

    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
    always @(*) begin
        // Default values
        next_state = current_state;
        next_data_out = 1'b0;
        next_data_valid = 1'b0;
        next_clock_recovered = 1'b0;
        next_sample_cnt_reset = 1'b0;
        next_sample_cnt_en = 1'b0;
        
        case (current_state)
            IDLE: begin
                if (manchester_in != prev_sample) begin
                    next_state = FIRST_HALF;
                    next_sample_cnt_reset = 1'b1;
                end
            end
            
            FIRST_HALF: begin
                if (sample_cnt == 2'b01) begin
                    next_state = SECOND_HALF;
                    next_data_out = polarity ? ~manchester_in : manchester_in;
                    next_clock_recovered = 1'b1;
                    next_sample_cnt_reset = 1'b1;
                end else begin
                    next_sample_cnt_en = 1'b1;
                end
            end
            
            SECOND_HALF: begin
                if (sample_cnt == 2'b01) begin
                    next_state = FIRST_HALF;
                    next_data_valid = 1'b1;
                    next_sample_cnt_reset = 1'b1;
                end else begin
                    next_sample_cnt_en = 1'b1;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule

// Main Manchester decoder module
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
    reg next_data_out;
    reg next_data_valid;
    reg next_clock_recovered;
    reg [1:0] next_state;
    reg next_sample_cnt_reset;
    reg next_sample_cnt_en;
    
    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
    // Instantiate sample counter module
    sample_counter #(
        .MAX_COUNT(2)
    ) sample_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count_en(next_sample_cnt_en),
        .reset(next_sample_cnt_reset),
        .count(sample_cnt)
    );
    
    // Instantiate state transition logic module
    state_transition_logic state_logic_inst (
        .current_state(state),
        .sample_cnt(sample_cnt),
        .manchester_in(manchester_in),
        .prev_sample(prev_sample),
        .polarity(polarity),
        .next_state(next_state),
        .next_data_out(next_data_out),
        .next_data_valid(next_data_valid),
        .next_clock_recovered(next_clock_recovered),
        .next_sample_cnt_reset(next_sample_cnt_reset),
        .next_sample_cnt_en(next_sample_cnt_en)
    );
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_out <= 1'b0;
            data_valid <= 1'b0;
            clock_recovered <= 1'b0;
            prev_sample <= 1'b0;
        end else begin
            state <= next_state;
            data_out <= next_data_out;
            data_valid <= next_data_valid;
            clock_recovered <= next_clock_recovered;
            prev_sample <= manchester_in;
        end
    end
endmodule