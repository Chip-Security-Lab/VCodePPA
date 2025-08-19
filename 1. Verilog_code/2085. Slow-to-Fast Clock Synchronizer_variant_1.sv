//SystemVerilog
module slow_to_fast_sync #(parameter WIDTH = 12) (
    input wire slow_clk,
    input wire fast_clk,
    input wire rst_n,
    input wire [WIDTH-1:0] slow_data,
    output reg [WIDTH-1:0] fast_data,
    output reg data_valid
);
    reg slow_toggle;
    reg [WIDTH-1:0] slow_data_latched;
    reg [2:0] slow_toggle_sync;
    reg fast_toggle_synced;
    reg [WIDTH-1:0] fast_data_latched;

    // Subtractor signals for 3-bit leading-borrow subtractor
    wire [2:0] subtractor_a;
    wire [2:0] subtractor_b;
    wire [2:0] subtractor_diff;
    wire subtractor_borrow_out;

    //////////////////////////////////////////////////////////////////////////////
    // Slow Clock Domain - Data Latching and Toggle Generation
    //////////////////////////////////////////////////////////////////////////////
    // Function: Latch slow_data and toggle slow_toggle on each slow_clk edge
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_toggle <= 1'b0;
            slow_data_latched <= {WIDTH{1'b0}};
        end else begin
            slow_toggle <= ~slow_toggle;
            slow_data_latched <= slow_data;
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // Fast Clock Domain - Toggle Synchronization
    //////////////////////////////////////////////////////////////////////////////
    // Function: Synchronize slow_toggle to fast_clk domain
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            slow_toggle_sync <= 3'b000;
        end else begin
            slow_toggle_sync <= {slow_toggle_sync[1:0], slow_toggle};
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // Fast Clock Domain - Synchronized Toggle Latching
    //////////////////////////////////////////////////////////////////////////////
    // Function: Latch the synchronized toggle for edge detection
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_toggle_synced <= 1'b0;
        end else begin
            fast_toggle_synced <= slow_toggle_sync[2];
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // Fast Clock Domain - Data Capture Logic
    //////////////////////////////////////////////////////////////////////////////
    // Function: Detect toggle edge and capture data when new data is available
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_data_latched <= {WIDTH{1'b0}};
        end else if (subtractor_diff[0] == 1'b1) begin
            fast_data_latched <= slow_data_latched;
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // Fast Clock Domain - Data Valid Generation
    //////////////////////////////////////////////////////////////////////////////
    // Function: Generate data_valid pulse when new data is captured
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= (subtractor_diff[0] == 1'b1);
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // Fast Clock Domain - Output Data Register
    //////////////////////////////////////////////////////////////////////////////
    // Function: Output captured data when data_valid is asserted
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_data <= {WIDTH{1'b0}};
        end else if (data_valid) begin
            fast_data <= fast_data_latched;
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // 3-bit Leading Borrow Subtractor Instantiation
    //////////////////////////////////////////////////////////////////////////////
    assign subtractor_a = {2'b00, slow_toggle_sync[2]};
    assign subtractor_b = {2'b00, fast_toggle_synced};

    leading_borrow_subtractor_3bit u_lbs3 (
        .a    (subtractor_a),
        .b    (subtractor_b),
        .diff (subtractor_diff),
        .borrow_out (subtractor_borrow_out)
    );

endmodule

// 3位先行借位减法器
module leading_borrow_subtractor_3bit(
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire [2:0] diff,
    output wire       borrow_out
);
    wire [2:0] generate_borrow;
    wire [2:0] propagate_borrow;
    wire [3:0] borrow;

    // Generate and propagate
    assign generate_borrow[0] = ~a[0] & b[0];
    assign propagate_borrow[0] = ~(a[0] ^ b[0]);
    assign generate_borrow[1] = ~a[1] & b[1];
    assign propagate_borrow[1] = ~(a[1] ^ b[1]);
    assign generate_borrow[2] = ~a[2] & b[2];
    assign propagate_borrow[2] = ~(a[2] ^ b[2]);

    // Borrow chain
    assign borrow[0] = 1'b0;
    assign borrow[1] = generate_borrow[0] | (propagate_borrow[0] & borrow[0]);
    assign borrow[2] = generate_borrow[1] | (propagate_borrow[1] & borrow[1]);
    assign borrow[3] = generate_borrow[2] | (propagate_borrow[2] & borrow[2]);

    // Difference bits
    assign diff[0] = a[0] ^ b[0] ^ borrow[0];
    assign diff[1] = a[1] ^ b[1] ^ borrow[1];
    assign diff[2] = a[2] ^ b[2] ^ borrow[2];

    assign borrow_out = borrow[3];
endmodule