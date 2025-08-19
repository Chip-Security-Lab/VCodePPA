//SystemVerilog
module barrel_shifter_registered (
  input clk,
  input enable,
  input [15:0] data,
  input [3:0] shift,
  input direction, // 0=right, 1=left
  output reg [15:0] shifted_data
);

  reg [15:0] data_reg;
  reg [3:0] shift_reg;
  reg direction_reg;
  reg [15:0] shift_left_result;
  reg [15:0] shift_right_result;

  always @(posedge clk) begin
    if (enable) begin
      data_reg <= data;
      shift_reg <= shift;
      direction_reg <= direction;
    end
  end

  always @(*) begin
    // Efficient barrel shifter implementation using case statement
    case (shift_reg)
      4'd0: begin
        shift_left_result  = data_reg;
        shift_right_result = data_reg;
      end
      4'd1: begin
        shift_left_result  = {data_reg[14:0], 1'b0};
        shift_right_result = {1'b0, data_reg[15:1]};
      end
      4'd2: begin
        shift_left_result  = {data_reg[13:0], 2'b00};
        shift_right_result = {2'b00, data_reg[15:2]};
      end
      4'd3: begin
        shift_left_result  = {data_reg[12:0], 3'b000};
        shift_right_result = {3'b000, data_reg[15:3]};
      end
      4'd4: begin
        shift_left_result  = {data_reg[11:0], 4'b0000};
        shift_right_result = {4'b0000, data_reg[15:4]};
      end
      4'd5: begin
        shift_left_result  = {data_reg[10:0], 5'b00000};
        shift_right_result = {5'b00000, data_reg[15:5]};
      end
      4'd6: begin
        shift_left_result  = {data_reg[9:0], 6'b000000};
        shift_right_result = {6'b000000, data_reg[15:6]};
      end
      4'd7: begin
        shift_left_result  = {data_reg[8:0], 7'b0000000};
        shift_right_result = {7'b0000000, data_reg[15:7]};
      end
      4'd8: begin
        shift_left_result  = {data_reg[7:0], 8'b00000000};
        shift_right_result = {8'b00000000, data_reg[15:8]};
      end
      4'd9: begin
        shift_left_result  = {data_reg[6:0], 9'b000000000};
        shift_right_result = {9'b000000000, data_reg[15:9]};
      end
      4'd10: begin
        shift_left_result  = {data_reg[5:0], 10'b0000000000};
        shift_right_result = {10'b0000000000, data_reg[15:10]};
      end
      4'd11: begin
        shift_left_result  = {data_reg[4:0], 11'b00000000000};
        shift_right_result = {11'b00000000000, data_reg[15:11]};
      end
      4'd12: begin
        shift_left_result  = {data_reg[3:0], 12'b000000000000};
        shift_right_result = {12'b000000000000, data_reg[15:12]};
      end
      4'd13: begin
        shift_left_result  = {data_reg[2:0], 13'b0000000000000};
        shift_right_result = {13'b0000000000000, data_reg[15:13]};
      end
      4'd14: begin
        shift_left_result  = {data_reg[1:0], 14'b00000000000000};
        shift_right_result = {14'b00000000000000, data_reg[15:14]};
      end
      4'd15: begin
        shift_left_result  = {data_reg[0], 15'b000000000000000};
        shift_right_result = {15'b000000000000000, data_reg[15]};
      end
      default: begin
        shift_left_result  = {16{1'b0}};
        shift_right_result = {16{1'b0}};
      end
    endcase
  end

  wire [15:0] barrel_shifted_result;
  assign barrel_shifted_result = direction_reg ? shift_left_result : shift_right_result;

  always @(posedge clk) begin
    if (enable)
      shifted_data <= barrel_shifted_result;
  end

endmodule