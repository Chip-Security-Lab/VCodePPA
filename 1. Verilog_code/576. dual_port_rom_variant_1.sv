//SystemVerilog
module dual_port_rom (
    input wire clk,
    input wire rst_n,
    
    // Port A interface with Valid-Ready handshake
    input wire [3:0] addr_a,
    input wire valid_a,
    output reg ready_a,
    output reg [7:0] data_a,
    output reg valid_out_a,
    input wire ready_out_a,
    
    // Port B interface with Valid-Ready handshake
    input wire [3:0] addr_b,
    input wire valid_b,
    output reg ready_b,
    output reg [7:0] data_b,
    output reg valid_out_b,
    input wire ready_out_b
);
    reg [7:0] rom [0:15];
    
    // Internal registers for latching addresses
    reg [3:0] addr_a_latch, addr_b_latch;
    reg addr_a_valid, addr_b_valid;
    
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'hAB; rom[9] = 8'hCD; rom[10] = 8'hEF; rom[11] = 8'h01;
        rom[12] = 8'h23; rom[13] = 8'h45; rom[14] = 8'h67; rom[15] = 8'h89;
    end
    
    // Port A handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_a <= 1'b1;
            addr_a_valid <= 1'b0;
            addr_a_latch <= 4'h0;
            valid_out_a <= 1'b0;
            data_a <= 8'h0;
        end else begin
            // Input handshake
            if (valid_a && ready_a) begin
                addr_a_latch <= addr_a;
                addr_a_valid <= 1'b1;
                ready_a <= 1'b0;  // Not ready for next address until current one is processed
            end
            
            // Output handshake
            if (addr_a_valid && !valid_out_a) begin
                data_a <= rom[addr_a_latch];
                valid_out_a <= 1'b1;
            end
            
            if (valid_out_a && ready_out_a) begin
                valid_out_a <= 1'b0;
                addr_a_valid <= 1'b0;
                ready_a <= 1'b1;  // Ready for next address
            end
        end
    end
    
    // Port B handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_b <= 1'b1;
            addr_b_valid <= 1'b0;
            addr_b_latch <= 4'h0;
            valid_out_b <= 1'b0;
            data_b <= 8'h0;
        end else begin
            // Input handshake
            if (valid_b && ready_b) begin
                addr_b_latch <= addr_b;
                addr_b_valid <= 1'b1;
                ready_b <= 1'b0;  // Not ready for next address until current one is processed
            end
            
            // Output handshake
            if (addr_b_valid && !valid_out_b) begin
                data_b <= rom[addr_b_latch];
                valid_out_b <= 1'b1;
            end
            
            if (valid_out_b && ready_out_b) begin
                valid_out_b <= 1'b0;
                addr_b_valid <= 1'b0;
                ready_b <= 1'b1;  // Ready for next address
            end
        end
    end
endmodule