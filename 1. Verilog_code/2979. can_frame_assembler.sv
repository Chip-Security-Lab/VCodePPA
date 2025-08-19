module can_frame_assembler(
  input wire clk, rst_n,
  input wire [10:0] id,
  input wire [7:0] data [0:7],
  input wire [3:0] dlc,
  input wire rtr, ide, assemble,
  output reg [127:0] frame,
  output reg frame_ready
);
  reg [7:0] state;
  reg [14:0] crc;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame <= 0;
      frame_ready <= 0;
    end else if (assemble) begin
      // SOF (1 bit)
      frame[0] <= 0;
      // Identifier (11 bits)
      frame[11:1] <= id;
      // RTR, IDE, r0 bits
      frame[12] <= rtr;
      frame[13] <= ide;
      frame[14] <= 0; // r0 reserved bit
      // DLC (4 bits)
      frame[18:15] <= dlc;
      // Data (0-8 bytes)
      if (!rtr) begin
        frame[82:19] <= {data[0], data[1], data[2], data[3], 
                        data[4], data[5], data[6], data[7]};
      end
      frame_ready <= 1;
    end
  end
endmodule