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
    
    localparam IDLE = 2'b00, FIRST_HALF = 2'b01, SECOND_HALF = 2'b10;
    
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
            
            case (state)
                IDLE: begin
                    if (manchester_in != prev_sample) begin
                        state <= FIRST_HALF;
                        sample_cnt <= 2'b00;
                    end
                end
                
                FIRST_HALF: begin
                    if (sample_cnt == 2'b01) begin
                        state <= SECOND_HALF;
                        data_out <= polarity ? ~manchester_in : manchester_in;
                        clock_recovered <= 1'b1;
                    end else
                        sample_cnt <= sample_cnt + 1'b1;
                end
                
                SECOND_HALF: begin
                    if (sample_cnt == 2'b01) begin
                        state <= FIRST_HALF;
                        data_valid <= 1'b1;
                        sample_cnt <= 2'b00;
                    end else
                        sample_cnt <= sample_cnt + 1'b1;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule