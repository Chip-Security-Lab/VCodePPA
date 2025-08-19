//SystemVerilog
module rom_dual_port #(parameter W=32, D=1024)(
    input clk,
    input [9:0] addr1,
    input [9:0] addr2,
    output reg [W-1:0] dout1,
    output reg [W-1:0] dout2
);
    // Instantiate the memory module
    wire [W-1:0] dout1_mem;
    wire [W-1:0] dout2_mem;

    // Memory module instantiation
    dual_port_rom #(.W(W), .D(D)) memory_inst (
        .clk(clk),
        .addr1(addr1),
        .addr2(addr2),
        .dout1(dout1_mem),
        .dout2(dout2_mem)
    );

    // Output assignments
    always @(posedge clk) begin
        dout1 <= dout1_mem;
        dout2 <= dout2_mem;
    end
endmodule

// Dual-port ROM module
module dual_port_rom #(parameter W=32, D=1024)(
    input clk,
    input [9:0] addr1,
    input [9:0] addr2,
    output reg [W-1:0] dout1,
    output reg [W-1:0] dout2
);
    // Declare dual-port ROM storage
    reg [W-1:0] content [0:D-1];

    // Initialize some values for testing
    initial begin
        // Example initialization, should be replaced with actual values in use
        content[0] = 32'h00001111;
        content[1] = 32'h22223333;
        // $readmemh("dual_port.init", content); // Use in simulation
    end

    // Read operations for both ports
    always @(posedge clk) begin
        dout1 <= content[addr1];
        dout2 <= content[addr2];
    end
endmodule