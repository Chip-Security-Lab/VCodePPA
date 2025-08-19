//SystemVerilog
module frame_assembler #(parameter DATA_W=8, HEADER=8'hAA) (
    input clk, rst, en,
    input [DATA_W-1:0] payload,
    output reg [DATA_W-1:0] frame_out,
    output reg frame_valid,
    output reg ready_in,
    input ready_out
);

    reg [1:0] state;
    reg [DATA_W-1:0] payload_stage1;
    reg valid_stage1, valid_stage2;
    reg [DATA_W-1:0] frame_data_stage1, frame_data_stage2;
    
    // LUT-based state transition logic
    reg [1:0] next_state;
    reg [1:0] state_lut [0:3];
    reg [1:0] next_state_lut [0:3];
    
    initial begin
        state_lut[0] = 2'b01;  // State 0 -> State 1
        state_lut[1] = 2'b10;  // State 1 -> State 2
        state_lut[2] = 2'b00;  // State 2 -> State 0
        state_lut[3] = 2'b00;  // Invalid state -> State 0
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            valid_stage1 <= 0;
            frame_data_stage1 <= 0;
            payload_stage1 <= 0;
            ready_in <= 1;
        end else begin
            next_state = state_lut[state];
            
            if (state == 0 && en && ready_out) begin
                frame_data_stage1 <= HEADER;
                payload_stage1 <= payload;
                valid_stage1 <= 1;
                state <= next_state;
                ready_in <= 0;
            end else if (state == 0) begin
                valid_stage1 <= 0;
                ready_in <= 1;
            end else if (state == 1 && ready_out) begin
                frame_data_stage1 <= payload_stage1;
                valid_stage1 <= 1;
                state <= next_state;
            end else if (state == 2 && ready_out) begin
                valid_stage1 <= 0;
                state <= next_state;
                ready_in <= 1;
            end
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage2 <= 0;
            frame_data_stage2 <= 0;
        end else if (ready_out) begin
            valid_stage2 <= valid_stage1;
            frame_data_stage2 <= frame_data_stage1;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_out <= 0;
            frame_valid <= 0;
        end else if (ready_out) begin
            frame_out <= frame_data_stage2;
            frame_valid <= valid_stage2;
        end
    end
endmodule