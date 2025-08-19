//SystemVerilog
module BiDirMux #(
    parameter DW = 8
)(
    inout  [DW-1:0]           bus,
    input  [(4*DW)-1:0]       tx,
    output [(4*DW)-1:0]       rx,
    input  [1:0]              sel,
    input                     oe,
    input                     clk,
    input                     rst_n
);

    // Internal wires for combinational logic
    wire [DW-1:0] tx_mux_data_comb;
    wire          tx_mux_oe_comb;

    // Combinational logic for selecting tx data
    assign tx_mux_data_comb = tx[(sel*DW) +: DW];
    assign tx_mux_oe_comb   = oe;

    // Stage 1: Register selected tx data and oe
    reg [DW-1:0] tx_stage1_data_reg;
    reg          tx_stage1_oe_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_stage1_data_reg <= {DW{1'b0}};
            tx_stage1_oe_reg   <= 1'b0;
        end else begin
            tx_stage1_data_reg <= tx_mux_data_comb;
            tx_stage1_oe_reg   <= tx_mux_oe_comb;
        end
    end

    // Stage 2: Register tx data and oe again for output
    reg [DW-1:0] tx_stage2_data_reg;
    reg          tx_stage2_oe_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_stage2_data_reg <= {DW{1'b0}};
            tx_stage2_oe_reg   <= 1'b0;
        end else begin
            tx_stage2_data_reg <= tx_stage1_data_reg;
            tx_stage2_oe_reg   <= tx_stage1_oe_reg;
        end
    end

    // Bus driver: Drive bus only if output enable is asserted
    assign bus = tx_stage2_oe_reg ? tx_stage2_data_reg : {DW{1'bz}};

    // Stage 3: Register the bus value for receive path (for all slices)
    reg [DW-1:0] bus_stage1_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bus_stage1_reg <= {DW{1'b0}};
        else
            bus_stage1_reg <= bus;
    end

    // Stage 4: Pipeline the select signal for receive path to align with data
    reg [1:0] sel_stage1_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sel_stage1_reg <= 2'b00;
        else
            sel_stage1_reg <= sel;
    end

    // Combinational logic for receive path (update rx data for all channels)
    wire [DW-1:0] rx_stage1_comb [3:0];
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : RX_COMB_LOGIC
            assign rx_stage1_comb[i] = (sel_stage1_reg == i) ? bus_stage1_reg : {DW{1'bz}};
        end
    endgenerate

    // Stage 5: Register receive data for all channels
    reg [DW-1:0] rx_stage1_reg [3:0];
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < 4; j = j + 1)
                rx_stage1_reg[j] <= {DW{1'b0}};
        end else begin
            for (j = 0; j < 4; j = j + 1)
                rx_stage1_reg[j] <= rx_stage1_comb[j];
        end
    end

    // Flatten rx output
    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin: RX_ASSIGN_BLOCK
            assign rx[(k+1)*DW-1:k*DW] = rx_stage1_reg[k];
        end
    endgenerate

endmodule