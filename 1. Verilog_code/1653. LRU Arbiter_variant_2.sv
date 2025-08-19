//SystemVerilog
module lru_arbiter #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output [N-1:0] grant,
  output busy
);

  wire [N-1:0] grant_int;
  wire busy_int;
  
  request_handler #(.N(N)) u_request_handler (
    .clk(clk),
    .rst(rst),
    .request(request),
    .grant(grant_int),
    .busy(busy_int)
  );
  
  grant_controller #(.N(N)) u_grant_controller (
    .clk(clk),
    .rst(rst),
    .grant_in(grant_int),
    .grant_out(grant),
    .busy(busy_int)
  );

endmodule

module request_handler #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output reg [N-1:0] grant,
  output reg busy
);
  
  reg [N*N-1:0] lru_matrix;
  reg [N-1:0] request_mask;
  reg found;
  
  always @(posedge clk) begin
    if (rst) begin
      lru_matrix <= 0;
      grant <= 0;
      busy <= 0;
      request_mask <= 0;
    end else begin
      request_mask <= request;
      busy <= |request;
      
      if (|request) begin
        found = 0;
        grant <= 0;
        
        // Use priority encoder style implementation
        for (int k = 0; k < N; k++) begin
          if (!found && request_mask[k]) begin
            grant <= (1 << k);
            found = 1;
          end
        end
      end else begin
        grant <= 0;
      end
    end
  end
  
endmodule

module grant_controller #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] grant_in,
  output reg [N-1:0] grant_out,
  input busy
);
  
  always @(posedge clk) begin
    if (rst) begin
      grant_out <= 0;
    end else begin
      grant_out <= grant_in;
    end
  end
  
endmodule