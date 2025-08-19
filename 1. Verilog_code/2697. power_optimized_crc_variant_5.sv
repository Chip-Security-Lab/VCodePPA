//SystemVerilog
module power_optimized_crc_pipelined(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_req,  // Changed from data_valid to data_req
    input wire power_save,
    output reg data_ack,  // Added new output signal for acknowledgment
    output reg [7:0] crc
);
    parameter [7:0] POLY = 8'h07;
    
    // Pipeline stage 1 signals
    reg [7:0] data_stage1;
    reg req_stage1;
    reg [7:0] crc_stage1;
    reg ack_stage1;
    
    // Pipeline stage 2 signals
    reg [7:0] data_stage2;
    reg req_stage2;
    reg [7:0] crc_stage2;
    reg ack_stage2;
    
    // Pipeline stage 3 signals
    reg [7:0] data_stage3;
    reg req_stage3;
    reg [7:0] crc_stage3;
    reg ack_stage3;
    
    // Handshake signals
    reg data_received;
    
    wire gated_clk = clk & ~power_save;
    
    // Handshake logic - generate acknowledge when data is received
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            data_ack <= 1'b0;
            data_received <= 1'b0;
        end else begin
            if (data_req && !data_received) begin
                data_ack <= 1'b1;
                data_received <= 1'b1;
            end else if (!data_req) begin
                data_ack <= 1'b0;
                data_received <= 1'b0;
            end
        end
    end
    
    // Stage 1: Input registration and initial XOR
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 8'h00;
            req_stage1 <= 1'b0;
            crc_stage1 <= 8'h00;
            ack_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data;
            req_stage1 <= data_req && !data_received;
            crc_stage1 <= {crc[6:0], 1'b0};
            ack_stage1 <= data_ack;
        end
    end
    
    // Stage 2: Polynomial selection
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            data_stage2 <= 8'h00;
            req_stage2 <= 1'b0;
            crc_stage2 <= 8'h00;
            ack_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            req_stage2 <= req_stage1;
            crc_stage2 <= (crc_stage1[7] ^ data_stage1[0]) ? POLY : 8'h00;
            ack_stage2 <= ack_stage1;
        end
    end
    
    // Stage 3: Final XOR and output
    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            data_stage3 <= 8'h00;
            req_stage3 <= 1'b0;
            crc_stage3 <= 8'h00;
            ack_stage3 <= 1'b0;
            crc <= 8'h00;
        end else begin
            data_stage3 <= data_stage2;
            req_stage3 <= req_stage2;
            crc_stage3 <= crc_stage1 ^ crc_stage2;
            ack_stage3 <= ack_stage2;
            if (req_stage3) begin
                crc <= crc_stage3;
            end
        end
    end
endmodule