module frame_assembler #(parameter DATA_W=8, HEADER=8'hAA) (
    input clk, rst, en,
    input [DATA_W-1:0] payload,
    output reg [DATA_W-1:0] frame_out,
    output reg frame_valid
);
reg [1:0] state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= 0;
        frame_out <= 0;
        frame_valid <= 0;
    end else case(state)
        0: if(en) begin
            frame_out <= HEADER;
            frame_valid <= 1;
            state <= 1;
        end
        1: begin
            frame_out <= payload;
            state <= 2;
        end
        2: begin
            frame_valid <= 0;
            state <= 0;
        end
    endcase
end
endmodule