module can_arbitration(
  input wire clk, rst_n,
  input wire can_rx,
  input wire [10:0] tx_id,
  input wire tx_start,
  output reg can_tx,
  output reg arbitration_lost
);
  reg [10:0] shift_id;
  reg [3:0] bit_count;
  reg in_arbitration;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arbitration_lost <= 0;
      in_arbitration <= 0;
      can_tx <= 1;
      bit_count <= 0;
    end else if (tx_start) begin
      shift_id <= tx_id;
      in_arbitration <= 1;
      bit_count <= 0;
    end else if (in_arbitration && bit_count < 11) begin
      can_tx <= shift_id[10];
      shift_id <= {shift_id[9:0], 1'b0};
      arbitration_lost <= (can_rx == 0 && shift_id[10] == 1);
      bit_count <= bit_count + 1;
    end
  end
endmodule