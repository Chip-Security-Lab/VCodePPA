//SystemVerilog
module state_machine_crc(
    input wire clk,
    input wire rst,
    input wire req,
    input wire [7:0] data,
    output reg [15:0] crc_out,
    output reg ack
);
    parameter [15:0] POLY = 16'h1021;
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    
    // Pipeline stage 1 registers
    reg [1:0] state_stage1;
    reg [3:0] bit_count_stage1;
    reg req_reg_stage1;
    reg [7:0] data_stage1;
    reg [15:0] crc_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] state_stage2;
    reg [3:0] bit_count_stage2;
    reg [7:0] data_stage2;
    reg [15:0] crc_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [1:0] state_stage3;
    reg [15:0] crc_stage3;
    reg valid_stage3;
    
    // Pipeline control signals
    wire stage1_ready;
    wire stage2_ready;
    wire stage3_ready;
    
    assign stage1_ready = (state_stage1 == IDLE) || (state_stage1 == FINALIZE);
    assign stage2_ready = !valid_stage2 || (state_stage2 == FINALIZE);
    assign stage3_ready = !valid_stage3 || (state_stage3 == FINALIZE);
    
    // Stage 1: Input and state management
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1 <= IDLE;
            bit_count_stage1 <= 4'd0;
            req_reg_stage1 <= 1'b0;
            data_stage1 <= 8'd0;
            crc_stage1 <= 16'hFFFF;
        end else if (stage1_ready) begin
            req_reg_stage1 <= req;
            data_stage1 <= data;
            
            if (state_stage1 == IDLE) begin
                if (req && !req_reg_stage1) begin
                    state_stage1 <= PROCESS;
                    bit_count_stage1 <= 4'd0;
                    crc_stage1 <= 16'hFFFF;
                end
            end else if (state_stage1 == FINALIZE) begin
                if (!req) begin
                    state_stage1 <= IDLE;
                end
            end
        end
    end
    
    // Stage 2: CRC calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage2 <= IDLE;
            bit_count_stage2 <= 4'd0;
            data_stage2 <= 8'd0;
            crc_stage2 <= 16'hFFFF;
            valid_stage2 <= 1'b0;
        end else if (stage2_ready) begin
            if (state_stage1 == PROCESS) begin
                state_stage2 <= state_stage1;
                bit_count_stage2 <= bit_count_stage1;
                data_stage2 <= data_stage1;
                crc_stage2 <= {crc_stage1[14:0], 1'b0} ^ 
                            ((crc_stage1[15] ^ data_stage1[bit_count_stage1]) ? POLY : 16'h0);
                valid_stage2 <= 1'b1;
            end else begin
                state_stage2 <= state_stage1;
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Output and finalization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage3 <= IDLE;
            crc_stage3 <= 16'hFFFF;
            valid_stage3 <= 1'b0;
            crc_out <= 16'hFFFF;
            ack <= 1'b0;
        end else if (stage3_ready) begin
            if (valid_stage2 && state_stage2 == PROCESS) begin
                if (bit_count_stage2 == 4'd7) begin
                    state_stage3 <= FINALIZE;
                end else begin
                    state_stage3 <= PROCESS;
                end
                crc_stage3 <= crc_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                state_stage3 <= state_stage2;
                valid_stage3 <= valid_stage2;
            end
            
            if (state_stage3 == FINALIZE) begin
                crc_out <= crc_stage3;
                ack <= 1'b1;
            end else begin
                ack <= 1'b0;
            end
        end
    end
endmodule