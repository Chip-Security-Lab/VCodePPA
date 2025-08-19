module base64_encoder (
    input wire clk, rst_n, data_valid,
    input wire [7:0] data_in,
    output reg [5:0] base64_out,
    output reg valid_out
);
    localparam IDLE = 2'b00, PROC1 = 2'b01, PROC2 = 2'b10, PROC3 = 2'b11;
    
    reg [1:0] state;
    reg [15:0] buffer;
    reg [1:0] out_count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid_out <= 1'b0;
            out_count <= 2'b00;
        end else begin
            case (state)
                IDLE: begin
                    if (data_valid) begin
                        buffer[15:8] <= data_in;
                        state <= PROC1;
                        out_count <= 2'b00;
                    end
                    valid_out <= 1'b0;
                end
                PROC1: begin
                    base64_out <= buffer[15:10];
                    valid_out <= 1'b1;
                    out_count <= out_count + 1'b1;
                    if (out_count == 2'b11) state <= IDLE;
                    else state <= PROC2;
                end
                PROC2: begin
                    base64_out <= buffer[9:4];
                    valid_out <= 1'b1;
                    out_count <= out_count + 1'b1;
                    if (out_count == 2'b11) state <= IDLE;
                    else state <= PROC3;
                end
                PROC3: begin
                    base64_out <= buffer[3:0] << 2;
                    valid_out <= 1'b1;
                    out_count <= out_count + 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule