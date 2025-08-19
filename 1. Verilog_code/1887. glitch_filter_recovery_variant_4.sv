//SystemVerilog
module glitch_filter_recovery_axi (
    input wire clk,
    input wire rst_n,
    
    // Input interface with Valid-Ready handshake
    input wire in_valid,
    output reg in_ready,
    input wire [0:0] in_data,  // Single bit input data
    
    // Output interface with Valid-Ready handshake
    output reg out_valid,
    input wire out_ready,
    output reg [0:0] out_data,  // Single bit output data
    output reg out_last
);
    // States for FSM
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam WAITING_OUTPUT = 2'b10;
    
    // Internal signals
    reg [3:0] shift_reg;
    reg [0:0] clean_output;
    reg [1:0] state;
    
    // Pipeline registers for critical path segmentation
    reg [3:0] shift_reg_pipe;
    reg [0:0] input_data_pipe;
    reg pipeline_valid;
    
    // Intermediate evaluation signals
    reg all_zeros, all_ones;
    reg three_or_more_ones, three_or_more_zeros;
    
    // FSM for improved handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            in_ready <= 1'b1;
            pipeline_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (in_valid && in_ready) begin
                        state <= PROCESSING;
                        in_ready <= 1'b0;
                    end
                end
                
                PROCESSING: begin
                    // One cycle for processing
                    state <= WAITING_OUTPUT;
                end
                
                WAITING_OUTPUT: begin
                    if (out_valid && out_ready) begin
                        state <= IDLE;
                        in_ready <= 1'b1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Stage 1: Sample input and update shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 4'b0000;
            shift_reg_pipe <= 4'b0000;
            input_data_pipe <= 1'b0;
            pipeline_valid <= 1'b0;
        end else if (in_valid && in_ready) begin
            // Capture new data into shift register
            shift_reg <= {shift_reg[2:0], in_data[0]};
            // Prepare pipeline registers for stage 2
            shift_reg_pipe <= {shift_reg[2:0], in_data[0]};
            input_data_pipe <= in_data[0];
            pipeline_valid <= 1'b1;
        end else begin
            pipeline_valid <= 1'b0;
        end
    end
    
    // Stage 2: Evaluate conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            all_zeros <= 1'b0;
            all_ones <= 1'b0;
            three_or_more_ones <= 1'b0;
            three_or_more_zeros <= 1'b0;
            clean_output <= 1'b0;
        end else if (pipeline_valid || state == PROCESSING) begin
            // Optimize detection by breaking down conditions
            all_zeros <= (shift_reg_pipe == 4'b0000);
            all_ones <= (shift_reg_pipe == 4'b1111);
            
            // Calculate three or more ones conditions (optimized logic)
            three_or_more_ones <= 
                (shift_reg_pipe[3:1] == 3'b111) || 
                (shift_reg_pipe[3:2] == 2'b11 && input_data_pipe == 1'b1) || 
                (shift_reg_pipe[3] == 1'b1 && shift_reg_pipe[1:0] == 2'b11);
            
            // Calculate three or more zeros conditions (optimized logic)
            three_or_more_zeros <= 
                (shift_reg_pipe[3:1] == 3'b000) || 
                (shift_reg_pipe[3:2] == 2'b00 && input_data_pipe == 1'b0) || 
                (shift_reg_pipe[3] == 1'b0 && shift_reg_pipe[1:0] == 2'b00);
                
            // Final output decision based on priority conditions
            if (all_zeros) begin
                clean_output <= 1'b0;
            end else if (all_ones) begin
                clean_output <= 1'b1;
            end else if (three_or_more_ones) begin
                clean_output <= 1'b1;
            end else if (three_or_more_zeros) begin
                clean_output <= 1'b0;
            end
            // default maintains current output
        end
    end
    
    // Output interface with valid-ready handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_data <= 1'b0;
            out_last <= 1'b0;
        end else if (state == WAITING_OUTPUT && !out_valid) begin
            out_valid <= 1'b1;
            out_data <= clean_output;
            out_last <= 1'b1; // Single data transfer
        end else if (out_valid && out_ready) begin
            out_valid <= 1'b0;
            out_last <= 1'b0;
        end
    end
    
endmodule