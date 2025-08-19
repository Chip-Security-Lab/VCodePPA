//SystemVerilog
module one_hot_arbiter(
  input wire clock, clear,
  input wire enable,
  input wire [7:0] requests,
  output reg [7:0] grants
);
  reg [7:0] priority_mask;
  wire [7:0] masked_requests;
  
  assign masked_requests = requests & ~priority_mask;
  
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      grants <= 8'h00;
      priority_mask <= 8'h01;
    end
    else if (enable) begin
      grants <= 8'h00;
      
      if (masked_requests[0]) begin
        grants <= 8'b00000001;
      end
      else if (masked_requests[1]) begin
        grants <= 8'b00000010;
      end
      else if (masked_requests[2]) begin
        grants <= 8'b00000100;
      end
      else if (masked_requests[3]) begin
        grants <= 8'b00001000;
      end
      else if (masked_requests[4]) begin
        grants <= 8'b00010000;
      end
      else if (masked_requests[5]) begin
        grants <= 8'b00100000;
      end
      else if (masked_requests[6]) begin
        grants <= 8'b01000000;
      end
      else if (masked_requests[7]) begin
        grants <= 8'b10000000;
      end
      else begin
        if (requests[0]) begin
          grants <= 8'b00000001;
        end
        else if (requests[1]) begin
          grants <= 8'b00000010;
        end
        else if (requests[2]) begin
          grants <= 8'b00000100;
        end
        else if (requests[3]) begin
          grants <= 8'b00001000;
        end
        else if (requests[4]) begin
          grants <= 8'b00010000;
        end
        else if (requests[5]) begin
          grants <= 8'b00100000;
        end
        else if (requests[6]) begin
          grants <= 8'b01000000;
        end
        else if (requests[7]) begin
          grants <= 8'b10000000;
        end
        else begin
          grants <= 8'h00;
        end
      end
      
      if (|grants) begin
        priority_mask <= {grants[6:0], grants[7]};
      end
    end
  end
endmodule