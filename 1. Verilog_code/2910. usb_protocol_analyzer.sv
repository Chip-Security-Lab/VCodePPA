module usb_protocol_analyzer(
    input wire clk,
    input wire reset,
    input wire dp,
    input wire dm,
    input wire start_capture,
    output reg [7:0] capture_data,
    output reg data_valid,
    output reg [2:0] packet_type,
    output reg [7:0] capture_count
);
    localparam IDLE = 3'd0, SYNC = 3'd1, PID = 3'd2, DATA = 3'd3, EOP = 3'd4;
    reg [2:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    // Line state definitions
    wire j_state = dp & ~dm;
    wire k_state = ~dp & dm;
    wire se0 = ~dp & ~dm;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            data_valid <= 1'b0;
            packet_type <= 3'd0;
            capture_count <= 8'd0;
            capture_data <= 8'd0;
        end else begin
            data_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (start_capture && k_state)
                        state <= SYNC;
                    capture_count <= 8'd0;
                end
                SYNC: begin
                    bit_count <= bit_count + 3'd1;
                    shift_reg <= {k_state, shift_reg[7:1]};
                    if (bit_count == 3'd7) begin
                        state <= PID;
                        bit_count <= 3'd0;
                        if (shift_reg == 8'b01010100)  // SYNC pattern (reversed)
                            packet_type <= 3'd1;       // Valid SYNC found
                    end
                end
                PID: begin
                    bit_count <= bit_count + 3'd1;
                    shift_reg <= {j_state, shift_reg[7:1]};
                    if (bit_count == 3'd7) begin
                        capture_data <= shift_reg;
                        data_valid <= 1'b1;
                        capture_count <= capture_count + 8'd1;
                        state <= DATA;
                        bit_count <= 3'd0;
                    end
                end
                DATA: begin
                    if (se0) begin
                        state <= EOP;
                    end else begin
                        bit_count <= bit_count + 3'd1;
                        shift_reg <= {j_state, shift_reg[7:1]};
                        if (bit_count == 3'd7) begin
                            capture_data <= shift_reg;
                            data_valid <= 1'b1;
                            capture_count <= capture_count + 8'd1;
                            bit_count <= 3'd0;
                        end
                    end
                end
                EOP: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule