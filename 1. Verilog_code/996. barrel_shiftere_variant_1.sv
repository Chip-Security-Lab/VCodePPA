//SystemVerilog
module barrel_shifter_valid_ready #(
    parameter DATA_WIDTH = 16,
    parameter SHAMT_WIDTH = 4
)(
    input                       clk,
    input                       rst_n,
    input  [DATA_WIDTH-1:0]     din,
    input  [SHAMT_WIDTH-1:0]    shamt,
    input                       dir,
    input                       din_valid,
    output                      din_ready,
    output [DATA_WIDTH-1:0]     dout,
    output                      dout_valid,
    input                       dout_ready
);

    // Handshake logic signals
    reg                         input_latched;
    reg                         dout_valid_reg;
    reg [DATA_WIDTH-1:0]        dout_reg;

    // Handshake logic
    assign din_ready  = !input_latched || (dout_ready && dout_valid_reg);
    assign dout       = dout_reg;
    assign dout_valid = dout_valid_reg;

    // Barrel shifter combinational logic
    wire [DATA_WIDTH-1:0] stage1, stage2, stage3;
    wire [DATA_WIDTH-1:0] shifter_din_wire;
    wire [SHAMT_WIDTH-1:0] shifter_shamt_wire;
    wire                   shifter_dir_wire;

    // Input registers moved after combinational logic (forward retiming)
    reg [DATA_WIDTH-1:0]    din_reg;
    reg [SHAMT_WIDTH-1:0]   shamt_reg;
    reg                     dir_reg;
    reg                     valid_reg;

    // Latch input handshake (moved before combinational logic; only handshake)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_latched <= 1'b0;
        end else begin
            if (din_valid && din_ready) begin
                input_latched <= 1'b1;
            end else if (dout_ready && dout_valid_reg) begin
                input_latched <= 1'b0;
            end
        end
    end

    // Combinational wires for shifter input
    assign shifter_din_wire   = din;
    assign shifter_shamt_wire = shamt;
    assign shifter_dir_wire   = dir;

    // Barrel shifter combinational stages
    assign stage1 = shifter_shamt_wire[0] ? (shifter_dir_wire ? {shifter_din_wire[DATA_WIDTH-2:0], shifter_din_wire[DATA_WIDTH-1]} : {shifter_din_wire[0], shifter_din_wire[DATA_WIDTH-1:1]}) : shifter_din_wire;
    assign stage2 = shifter_shamt_wire[1] ? (shifter_dir_wire ? {stage1[DATA_WIDTH-3:0], stage1[DATA_WIDTH-1:DATA_WIDTH-2]} : {stage1[1:0], stage1[DATA_WIDTH-1:2]}) : stage1;
    assign stage3 = shifter_shamt_wire[2] ? (shifter_dir_wire ? {stage2[DATA_WIDTH-5:0], stage2[DATA_WIDTH-1:DATA_WIDTH-4]} : {stage2[3:0], stage2[DATA_WIDTH-1:4]}) : stage2;
    wire [DATA_WIDTH-1:0] dout_wire = shifter_shamt_wire[3] ? (shifter_dir_wire ? {stage3[7:0], stage3[15:8]} : {stage3[7:0], stage3[15:8]}) : stage3;

    // Pipeline registers moved after combinational logic (retimed)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg     <= {DATA_WIDTH{1'b0}};
            shamt_reg   <= {SHAMT_WIDTH{1'b0}};
            dir_reg     <= 1'b0;
            valid_reg   <= 1'b0;
        end else begin
            if (din_valid && din_ready) begin
                din_reg     <= din;
                shamt_reg   <= shamt;
                dir_reg     <= dir;
                valid_reg   <= 1'b1;
            end else if (dout_ready && dout_valid_reg) begin
                valid_reg   <= 1'b0;
            end
        end
    end

    // Output pipeline register and handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg        <= {DATA_WIDTH{1'b0}};
            dout_valid_reg  <= 1'b0;
        end else begin
            if (valid_reg) begin
                dout_reg        <= (
                    shamt_reg[3] ? 
                        (dir_reg ? {stage3[7:0], stage3[15:8]} : {stage3[7:0], stage3[15:8]}) :
                        stage3
                );
                dout_valid_reg  <= 1'b1;
            end else if (dout_ready && dout_valid_reg) begin
                dout_valid_reg  <= 1'b0;
            end
        end
    end

endmodule