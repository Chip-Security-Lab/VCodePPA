module can_frame_parser(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  output reg [10:0] id,
  output reg [7:0] data [0:7],
  output reg [3:0] dlc,
  output reg rtr, ide, frame_valid
);
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  reg [2:0] state;
  reg [7:0] bit_count, byte_count;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= WAIT_SOF;
      frame_valid <= 0;
    end else if (bit_valid) begin
      case (state)
        WAIT_SOF: if (bit_in == 0) begin state <= GET_ID; bit_count <= 0; end
        GET_ID: begin
          if (bit_count < 11) begin
            id[10-bit_count] <= bit_in;
            bit_count <= bit_count + 1;
          end else begin
            state <= GET_CTRL;
            rtr <= bit_in;
            bit_count <= 0;
          end
        end
      endcase
    end
  end
endmodule