//SystemVerilog
module packet_framer(
    input wire clk, rst,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire sof, eof,
    output reg [7:0] data_out,
    output reg data_out_valid,
    input wire data_out_ready,
    output reg packet_done
);
    // State definitions
    localparam IDLE=3'd0, HEADER=3'd1, PAYLOAD=3'd2, 
               CRC=3'd3, TRAILER=3'd4, DONE=3'd5;
    
    // Pipeline stage 1 registers
    reg [2:0] state_stage1, next_stage1;
    reg [7:0] data_in_stage1;
    reg data_valid_stage1, sof_stage1, eof_stage1;
    reg [7:0] frame_header_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [2:0] state_stage2;
    reg [7:0] data_stage2;
    reg [7:0] byte_count_stage2;
    reg [15:0] crc_stage2;
    reg valid_stage2;
    reg process_data_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] data_out_stage3;
    reg data_out_valid_stage3;
    reg packet_done_stage3;
    
    // Handshaking signals and backpressure logic
    wire stage2_ready;
    wire stage3_ready;
    wire pipeline_stall;
    
    // Determine if each stage can accept new data
    assign stage3_ready = ~data_out_valid || data_out_ready;
    assign stage2_ready = ~valid_stage2 || stage3_ready;
    assign pipeline_stall = ~stage2_ready;
    
    // Pipeline stage 1: Input capturing and state determination
    always @(posedge clk) begin
        if (rst) begin
            state_stage1 <= IDLE;
            data_in_stage1 <= 8'h0;
            data_valid_stage1 <= 1'b0;
            sof_stage1 <= 1'b0;
            eof_stage1 <= 1'b0;
            frame_header_stage1 <= 8'hA5; // Fixed frame header
            valid_stage1 <= 1'b0;
        end else if (~pipeline_stall) begin
            // Register inputs
            data_in_stage1 <= data_in;
            data_valid_stage1 <= data_valid;
            sof_stage1 <= sof;
            eof_stage1 <= eof;
            
            // State machine logic
            state_stage1 <= next_stage1;
            valid_stage1 <= 1'b1; // Enable pipeline flow
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state_stage1)
            IDLE: next_stage1 = sof ? HEADER : IDLE;
            HEADER: next_stage1 = PAYLOAD;
            PAYLOAD: next_stage1 = eof_stage1 ? CRC : PAYLOAD;
            CRC: next_stage1 = (byte_count_stage2[0]) ? TRAILER : CRC;
            TRAILER: next_stage1 = DONE;
            DONE: next_stage1 = IDLE;
            default: next_stage1 = IDLE;
        endcase
    end
    
    // Pipeline stage 2: Data processing and CRC calculation
    always @(posedge clk) begin
        if (rst) begin
            state_stage2 <= IDLE;
            byte_count_stage2 <= 8'd0;
            crc_stage2 <= 16'd0;
            valid_stage2 <= 1'b0;
            process_data_stage2 <= 1'b0;
            data_stage2 <= 8'h0;
        end else if (valid_stage1 && stage2_ready) begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
            
            case (state_stage1)
                IDLE: begin
                    byte_count_stage2 <= 8'd0;
                    crc_stage2 <= 16'd0;
                    process_data_stage2 <= 1'b0;
                end
                HEADER: begin
                    data_stage2 <= frame_header_stage1;
                    process_data_stage2 <= 1'b1;
                end
                PAYLOAD: begin
                    if (data_valid_stage1) begin
                        data_stage2 <= data_in_stage1;
                        process_data_stage2 <= 1'b1;
                        byte_count_stage2 <= byte_count_stage2 + 8'd1;
                        // Simple CRC calculation
                        crc_stage2 <= crc_stage2 ^ {8'd0, data_in_stage1};
                    end else begin
                        process_data_stage2 <= 1'b0;
                    end
                end
                CRC: begin
                    case (byte_count_stage2[0])
                        1'b0: begin data_stage2 <= crc_stage2[7:0]; process_data_stage2 <= 1'b1; end
                        1'b1: begin data_stage2 <= crc_stage2[15:8]; process_data_stage2 <= 1'b1; end
                    endcase
                    byte_count_stage2 <= byte_count_stage2 + 8'd1;
                end
                TRAILER: begin
                    data_stage2 <= 8'h5A; // Fixed frame trailer
                    process_data_stage2 <= 1'b1;
                end
                DONE: begin
                    process_data_stage2 <= 1'b0;
                end
            endcase
        end else if (stage2_ready) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Pipeline stage 3: Output generation with valid-ready handshaking
    always @(posedge clk) begin
        if (rst) begin
            data_out_stage3 <= 8'h0;
            data_out_valid_stage3 <= 1'b0;
            packet_done_stage3 <= 1'b0;
        end else if (valid_stage2 && stage3_ready) begin
            data_out_stage3 <= data_stage2;
            data_out_valid_stage3 <= process_data_stage2;
            
            if (state_stage2 == DONE)
                packet_done_stage3 <= 1'b1;
            else
                packet_done_stage3 <= 1'b0;
        end else if (data_out_ready) begin
            // Clear valid flag when data is consumed
            data_out_valid_stage3 <= 1'b0;
            if (packet_done_stage3)
                packet_done_stage3 <= 1'b0;
        end
    end
    
    // Final output assignment with handshaking
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'h0;
            data_out_valid <= 1'b0;
            packet_done <= 1'b0;
        end else if (stage3_ready) begin
            // Update outputs only when downstream is ready
            data_out <= data_out_stage3;
            data_out_valid <= data_out_valid_stage3;
            packet_done <= packet_done_stage3;
        end
    end
endmodule